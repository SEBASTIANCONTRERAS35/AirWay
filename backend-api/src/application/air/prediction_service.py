# application/air/prediction_service.py
"""
Servicio de predicción PM2.5 con modelos de ML.

Carga modelos entrenados (GradientBoosting) y genera predicciones
de PM2.5 a 1h, 3h y 6h usando datos actuales del aggregator + Open-Meteo.

Patrón singleton: los modelos se cargan UNA sola vez en memoria.
"""

import os
import json
import logging
import math
import numpy as np
from datetime import datetime, timezone, timedelta
from django.core.cache import cache

logger = logging.getLogger(__name__)

# Directorio de modelos
MODEL_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "models",
)

# Breakpoints EPA para conversión PM2.5 → AQI
AQI_BREAKPOINTS = [
    (0.0, 12.0, 0, 50),
    (12.1, 35.4, 51, 100),
    (35.5, 55.4, 101, 150),
    (55.5, 150.4, 151, 200),
    (150.5, 250.4, 201, 300),
    (250.5, 350.4, 301, 400),
    (350.5, 500.4, 401, 500),
]


def pm25_to_aqi(pm25: float) -> int:
    """Convierte PM2.5 (µg/m³) a AQI (EPA US)."""
    if pm25 < 0:
        pm25 = 0
    for pm_lo, pm_hi, aqi_lo, aqi_hi in AQI_BREAKPOINTS:
        if pm25 <= pm_hi:
            return int(((aqi_hi - aqi_lo) / (pm_hi - pm_lo)) * (pm25 - pm_lo) + aqi_lo)
    return 500


def _risk_level(aqi: int) -> str:
    """Nivel de riesgo basado en AQI."""
    if aqi <= 50:
        return "bajo"
    elif aqi <= 100:
        return "moderado"
    elif aqi <= 150:
        return "alto"
    elif aqi <= 200:
        return "muy_alto"
    return "peligroso"


class PredictionService:
    """
    Servicio de predicción PM2.5 con modelos ML.

    Usa patrón singleton para cargar modelos una sola vez.
    Mantiene historial en caché para calcular lag features.
    """

    _instance = None
    _models = {}
    _features = []
    _metrics = {}
    _loaded = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._loaded:
            self._load_models()

    def _load_models(self):
        """Carga modelos y metadata desde disco."""
        try:
            import joblib
        except ImportError:
            logger.error("joblib no instalado — predicción ML no disponible")
            return

        # Cargar feature names
        features_path = os.path.join(MODEL_DIR, "feature_names.json")
        if not os.path.exists(features_path):
            logger.warning(f"No se encontró {features_path} — predicción ML no disponible")
            return

        with open(features_path) as f:
            self._features = json.load(f)

        # Cargar métricas (RMSE para intervalos de confianza)
        metrics_path = os.path.join(MODEL_DIR, "metrics.json")
        if os.path.exists(metrics_path):
            with open(metrics_path) as f:
                metrics_data = json.load(f)
                for h in metrics_data.get("horizons", []):
                    self._metrics[h["horizon"]] = h

        # Cargar modelos
        for horizon in [1, 3, 6]:
            model_path = os.path.join(MODEL_DIR, f"pm25_predictor_{horizon}h.pkl")
            if os.path.exists(model_path):
                self._models[horizon] = joblib.load(model_path)
                size_mb = os.path.getsize(model_path) / (1024 * 1024)
                logger.info(f"Modelo {horizon}h cargado ({size_mb:.1f} MB)")
            else:
                logger.warning(f"Modelo no encontrado: {model_path}")

        self._loaded = bool(self._models)
        if self._loaded:
            logger.info(f"PredictionService listo: {len(self._models)} modelos, {len(self._features)} features")
        else:
            logger.warning("PredictionService: sin modelos cargados")

    @property
    def is_available(self) -> bool:
        return self._loaded and bool(self._models)

    def predict(self, air_data: dict, weather_data: dict, lat: float, lon: float) -> dict:
        """
        Genera predicciones de PM2.5 para 1h, 3h, 6h.

        Args:
            air_data: Datos del AirQualityAggregator (combined_aqi, pollutants, etc.)
            weather_data: Datos meteorológicos actuales de Open-Meteo
            lat, lon: Coordenadas del usuario

        Returns:
            dict con predicciones, intervalos de confianza, y tendencia
        """
        if not self.is_available:
            return self._fallback_prediction(air_data)

        # Construir vector de features
        features = self._build_features(air_data, weather_data, lat, lon)

        if features is None:
            return self._fallback_prediction(air_data)

        predictions = {}
        for horizon in [1, 3, 6]:
            if horizon not in self._models:
                continue

            model = self._models[horizon]
            feature_array = np.array([features]).astype(np.float64)

            try:
                pm25_pred = float(model.predict(feature_array)[0])
                pm25_pred = max(0, pm25_pred)  # PM2.5 no puede ser negativo

                aqi_pred = pm25_to_aqi(pm25_pred)

                # Intervalo de confianza basado en RMSE de validación
                rmse = self._metrics.get(f"{horizon}h", {}).get("test_rmse", 10)
                lower = max(0, pm25_pred - 1.96 * rmse)
                upper = pm25_pred + 1.96 * rmse

                predictions[f"{horizon}h"] = {
                    "pm25": round(pm25_pred, 1),
                    "aqi": aqi_pred,
                    "risk_level": _risk_level(aqi_pred),
                    "confidence_interval": {
                        "lower_pm25": round(lower, 1),
                        "upper_pm25": round(upper, 1),
                        "lower_aqi": pm25_to_aqi(lower),
                        "upper_aqi": pm25_to_aqi(upper),
                    },
                }
            except Exception as e:
                logger.error(f"Error en predicción {horizon}h: {e}")

        if not predictions:
            return self._fallback_prediction(air_data)

        # Calcular tendencia
        current_pm25 = self._get_current_pm25(air_data)
        pred_1h = predictions.get("1h", {}).get("pm25", current_pm25)

        if pred_1h > current_pm25 * 1.15:
            trend = "subiendo"
        elif pred_1h < current_pm25 * 0.85:
            trend = "bajando"
        else:
            trend = "estable"

        # Guardar en historial para futuros lags
        self._update_history(lat, lon, current_pm25, air_data, weather_data)

        return {
            "predictions": predictions,
            "trend": trend,
            "current_pm25": round(current_pm25, 1),
            "current_aqi": air_data.get("combined_aqi", 0),
            "model_available": True,
        }

    def _build_features(self, air_data: dict, weather: dict, lat: float, lon: float) -> list:
        """Construye el vector de features en el orden exacto del entrenamiento."""
        try:
            now = datetime.now(timezone.utc)
            hour = now.hour
            dow = now.weekday()
            month = now.month

            pollutants = air_data.get("pollutants", {})
            pm25 = self._get_pollutant_value(pollutants, "pm25", 0)
            pm10 = self._get_pollutant_value(pollutants, "pm10", 0)
            no2 = self._get_pollutant_value(pollutants, "no2", 0)
            ozone = self._get_pollutant_value(pollutants, "o3", 0)
            co = self._get_pollutant_value(pollutants, "co", 0)
            so2 = self._get_pollutant_value(pollutants, "so2", 0)
            dust = 0  # Open-Meteo current no siempre tiene dust

            # Meteorología
            temp = weather.get("temperature_2m", 20)
            humidity = weather.get("relative_humidity_2m", 50)
            dew_point = weather.get("dew_point_2m", 10)
            pressure = weather.get("surface_pressure", 760)
            wind_speed = weather.get("wind_speed_10m", 5)
            wind_dir = weather.get("wind_direction_10m", 180)
            wind_gusts = weather.get("wind_gusts_10m", 10)
            precip = weather.get("precipitation", 0)
            rain = weather.get("rain", 0)
            cloud = weather.get("cloud_cover", 50)
            sw_rad = weather.get("shortwave_radiation", 200)
            direct_rad = weather.get("direct_radiation", 100)

            # Temporales cíclicos
            hour_sin = math.sin(2 * math.pi * hour / 24)
            hour_cos = math.cos(2 * math.pi * hour / 24)
            dow_sin = math.sin(2 * math.pi * dow / 7)
            dow_cos = math.cos(2 * math.pi * dow / 7)
            month_sin = math.sin(2 * math.pi * month / 12)
            month_cos = math.cos(2 * math.pi * month / 12)
            is_weekend = 1 if dow >= 5 else 0
            is_dry = 1 if month in [11, 12, 1, 2, 3, 4] else 0

            # Lags del historial (caché)
            history = self._get_history(lat, lon)
            lag_1h = history.get("lag_1h", pm25)
            lag_2h = history.get("lag_2h", pm25)
            lag_3h = history.get("lag_3h", pm25)
            lag_6h = history.get("lag_6h", pm25)
            lag_12h = history.get("lag_12h", pm25)
            lag_24h = history.get("lag_24h", pm25)

            # Rolling stats del historial
            rolling_mean_3h = history.get("rolling_mean_3h", pm25)
            rolling_mean_6h = history.get("rolling_mean_6h", pm25)
            rolling_mean_12h = history.get("rolling_mean_12h", pm25)
            rolling_mean_24h = history.get("rolling_mean_24h", pm25)
            rolling_std_6h = history.get("rolling_std_6h", 5)
            rolling_std_24h = history.get("rolling_std_24h", 8)

            # Deltas
            delta_1h = pm25 - lag_1h
            delta_3h = pm25 - lag_3h
            delta_6h = pm25 - lag_6h

            # Max 24h
            max_24h = history.get("max_24h", pm25)

            # Derivados
            p_mean = 755  # Presión media CDMX aprox
            pressure_factor = max(0.1, min(2.0, 1 - (pressure - p_mean) / (3 * 15)))
            ventilation_index = wind_speed * pressure_factor
            stability_index = temp / (wind_speed + 0.5)
            hours_since_rain = history.get("hours_since_rain", 48)
            humidity_wind = humidity / (wind_speed + 0.5)

            # Construir vector en el MISMO orden que el entrenamiento
            feature_vector = [
                pm25, pm10, no2, ozone, co, so2, dust,
                temp, humidity, dew_point, pressure, wind_speed, wind_dir,
                wind_gusts, precip, rain, cloud, sw_rad, direct_rad,
                hour_sin, hour_cos, dow_sin, dow_cos, month_sin, month_cos,
                hour, month, is_weekend, is_dry,
                lag_1h, lag_2h, lag_3h, lag_6h, lag_12h, lag_24h,
                rolling_mean_3h, rolling_mean_6h, rolling_mean_12h, rolling_mean_24h,
                rolling_std_6h, rolling_std_24h,
                delta_1h, delta_3h, delta_6h,
                max_24h, ventilation_index, stability_index,
                hours_since_rain, humidity_wind,
            ]

            if len(feature_vector) != len(self._features):
                logger.warning(
                    f"Feature mismatch: esperado {len(self._features)}, "
                    f"obtenido {len(feature_vector)}"
                )
                return None

            # Reemplazar NaN/None con 0
            return [0.0 if (v is None or (isinstance(v, float) and math.isnan(v))) else float(v) for v in feature_vector]

        except Exception as e:
            logger.error(f"Error construyendo features: {e}")
            return None

    def _get_pollutant_value(self, pollutants: dict, key: str, default: float) -> float:
        """Extrae valor de un contaminante del dict del aggregator."""
        entry = pollutants.get(key)
        if entry and isinstance(entry, dict):
            return entry.get("value", default) or default
        return default

    def _get_current_pm25(self, air_data: dict) -> float:
        """Obtiene PM2.5 actual de los datos del aggregator."""
        pollutants = air_data.get("pollutants", {})
        return self._get_pollutant_value(pollutants, "pm25", 15.0)

    # ── Historial para lags ────────────────────────────────────

    def _get_history(self, lat: float, lon: float) -> dict:
        """Obtiene historial de PM2.5 del caché para calcular lags."""
        key = f"pm25_history:{lat:.2f}:{lon:.2f}"
        history = cache.get(key)
        if history and isinstance(history, list) and len(history) > 0:
            return self._compute_lag_features(history)
        return {}

    def _update_history(self, lat: float, lon: float, pm25: float,
                        air_data: dict = None, weather: dict = None):
        """Agrega lectura actual al historial en caché."""
        key = f"pm25_history:{lat:.2f}:{lon:.2f}"
        history = cache.get(key) or []

        now = datetime.now(timezone.utc)
        history.append({
            "pm25": pm25,
            "timestamp": now.isoformat(),
            "rain": weather.get("rain", 0) if weather else 0,
        })

        # Mantener solo últimas 25 horas
        cutoff = now - timedelta(hours=25)
        history = [
            h for h in history
            if datetime.fromisoformat(h["timestamp"]) > cutoff
        ]

        cache.set(key, history, timeout=90000)  # 25 horas

    def _compute_lag_features(self, history: list) -> dict:
        """Calcula lag features desde el historial."""
        now = datetime.now(timezone.utc)
        values = []
        for h in sorted(history, key=lambda x: x["timestamp"]):
            ts = datetime.fromisoformat(h["timestamp"])
            hours_ago = (now - ts).total_seconds() / 3600
            values.append((hours_ago, h["pm25"], h.get("rain", 0)))

        if not values:
            return {}

        result = {}
        pm25_values = [v[1] for v in values]

        # Lags: encontrar el valor más cercano a N horas atrás
        for lag in [1, 2, 3, 6, 12, 24]:
            closest = min(values, key=lambda x: abs(x[0] - lag))
            if abs(closest[0] - lag) < 1.5:  # Tolerancia de 1.5h
                result[f"lag_{lag}h"] = closest[1]
            else:
                result[f"lag_{lag}h"] = pm25_values[-1]  # Usar más reciente

        # Rolling means
        for window in [3, 6, 12, 24]:
            recent = [v[1] for v in values if v[0] <= window]
            if recent:
                result[f"rolling_mean_{window}h"] = sum(recent) / len(recent)

        # Rolling std
        for window in [6, 24]:
            recent = [v[1] for v in values if v[0] <= window]
            if len(recent) >= 2:
                mean = sum(recent) / len(recent)
                variance = sum((x - mean) ** 2 for x in recent) / (len(recent) - 1)
                result[f"rolling_std_{window}h"] = variance ** 0.5

        # Max 24h
        recent_24 = [v[1] for v in values if v[0] <= 24]
        if recent_24:
            result["max_24h"] = max(recent_24)

        # Hours since rain
        rain_hours = [v[0] for v in values if v[2] > 0.1]
        result["hours_since_rain"] = min(rain_hours) if rain_hours else min(168, max(v[0] for v in values))

        return result

    def _fallback_prediction(self, air_data: dict) -> dict:
        """Predicción simple basada en forecast de Open-Meteo cuando el modelo no está disponible."""
        current_aqi = air_data.get("combined_aqi", 0)
        return {
            "predictions": {},
            "trend": "desconocido",
            "current_pm25": self._get_current_pm25(air_data),
            "current_aqi": current_aqi,
            "model_available": False,
            "note": "Modelo ML no disponible, usando datos actuales",
        }
