"""
Motor físico de estimación de consumo de gasolina.

Base: VT-Micro (Rakha et al. 2004) simplificado + factores específicos México:
- Altitud CDMX 2240 msnm
- Temporada seca vs lluvias
- Hoy No Circula (estrés de rutas alternativas)
- Factores de emisión SEDEMA ZMVM 2020

Función pura: sin I/O. Portable a CoreML via coremltools si se requiere.

Referencias:
- VT-Micro: https://www.researchgate.net/publication/222656465
- Altitud effect: https://www.sciencedirect.com/science/article/abs/pii/S0016236111000627
- Road gradient: https://www.mdpi.com/2073-4433/16/2/143
- SEDEMA Inventario ZMVM 2020.
"""
import logging

from .vehicle_profile import VehicleProfile, FuelType

logger = logging.getLogger(__name__)

# ── Factores de emisión (SEDEMA + EPA) ───────────────────────────────────────
# kg CO2 por litro de combustible
CO2_KG_PER_L = {
    FuelType.MAGNA: 2.39,
    FuelType.PREMIUM: 2.39,
    FuelType.DIESEL: 2.68,
    FuelType.HYBRID: 2.39,   # se ajusta por eficiencia via conuee_km_per_l
    FuelType.ELECTRIC: 0.0,
}

# gramos PM2.5 por litro (SEDEMA ZMVM 2020, aproximado)
PM25_G_PER_L = {
    FuelType.MAGNA: 0.012,
    FuelType.PREMIUM: 0.010,
    FuelType.DIESEL: 0.195,  # diésel emite ~16x más PM2.5
    FuelType.HYBRID: 0.008,
    FuelType.ELECTRIC: 0.0,
}

# ── Constantes México ────────────────────────────────────────────────────────
CDMX_ALTITUDE_M = 2240
ALTITUDE_FUEL_FACTOR = 0.965   # -3.5% consumo vs nivel del mar (Fuel 2011)

# Densidad gasolina para conversiones OBD (no usado aquí pero documentado)
FUEL_DENSITY_G_PER_L_GASOLINE = 740.0


def estimate_fuel_liters(
    distance_km: float,
    vehicle: VehicleProfile,
    avg_speed_kmh: float = 35.0,
    avg_grade_pct: float = 0.0,
    temperature_c: float = 20.0,
    wind_headwind_kmh: float = 0.0,
    stops_count: int = 0,
    passengers: int = 1,
) -> dict:
    """
    Estima consumo + emisiones para un trayecto.

    Args:
        distance_km: distancia total de la ruta
        vehicle: VehicleProfile del usuario
        avg_speed_kmh: velocidad promedio esperada (tráfico afecta)
        avg_grade_pct: pendiente promedio (-5..+5). Positivo = subida neta
        temperature_c: temperatura ambiente (afecta A/C + cold-start)
        wind_headwind_kmh: viento de frente efectivo (positivo)
        stops_count: número de paros (semáforos, congestión)
        passengers: número de ocupantes (afecta peso)

    Returns:
        dict con: liters, co2_kg, pm25_g, confidence, breakdown, pesos_cost_base
    """
    logger.debug(
        "physics.estimate_fuel_liters vehicle=%s km=%.2f speed=%.1f grade=%.2f temp=%.1f wind=%.1f stops=%d pax=%d style=%.3f",
        vehicle.display_name, distance_km, avg_speed_kmh, avg_grade_pct,
        temperature_c, wind_headwind_kmh, stops_count, passengers, vehicle.driving_style,
    )

    if vehicle.is_electric:
        logger.debug("physics.estimate delegating to _electric_estimate")
        return _electric_estimate(distance_km, vehicle, avg_speed_kmh, avg_grade_pct)

    base_liters = max(0.01, distance_km) / max(5.0, vehicle.conuee_km_per_l)

    # 1. Altitud CDMX
    altitude_factor = ALTITUDE_FUEL_FACTOR

    # 2. Pendiente: cada 1% de grade promedio agrega ~4% consumo (literatura NREL)
    grade_factor = 1.0 + abs(avg_grade_pct) * 0.04

    # 3. Tráfico / stops-per-km. Stop-and-go puede añadir hasta 25%.
    stops_per_km = stops_count / max(distance_km, 1.0)
    traffic_factor = 1.0 + min(stops_per_km * 0.08, 0.25)

    # 4. Aire acondicionado + cold-start
    if temperature_c > 26:
        ac_factor = 1.08        # A/C encendido
    elif temperature_c < 5:
        ac_factor = 1.12        # cold-start + calefacción
    elif temperature_c < 12:
        ac_factor = 1.05        # mañana fría CDMX
    else:
        ac_factor = 1.0

    # 5. Viento de frente (0-25%)
    wind_factor = 1.0 + max(0.0, min(wind_headwind_kmh, 60.0)) / 60.0 * 0.25

    # 6. Estilo de conducción (EMA actualizada por CoreMotion)
    style_factor = max(0.85, min(vehicle.driving_style, 1.30))

    # 7. Pasajeros (~1.5% por cada adicional, 75kg asumido)
    passenger_factor = 1.0 + max(0, passengers - 1) * 0.015

    # 8. Curva de eficiencia U: óptimo ~80 km/h
    speed_factor = _speed_efficiency_curve(avg_speed_kmh)

    # Combinación multiplicativa
    liters = (
        base_liters
        * altitude_factor
        * grade_factor
        * traffic_factor
        * ac_factor
        * wind_factor
        * style_factor
        * passenger_factor
        * speed_factor
    )

    # Emisiones
    co2 = liters * CO2_KG_PER_L.get(vehicle.fuel_type, 2.39)
    pm25 = liters * PM25_G_PER_L.get(vehicle.fuel_type, 0.012)

    # Confianza heurística: más factores "nominales" = más confianza
    deviations = [
        abs(altitude_factor - 0.965),
        abs(grade_factor - 1.0),
        abs(traffic_factor - 1.0),
        abs(ac_factor - 1.0),
        abs(wind_factor - 1.0),
        abs(style_factor - 1.0),
        abs(speed_factor - 1.0),
    ]
    avg_dev = sum(deviations) / len(deviations)
    confidence = max(0.55, min(0.92, 0.92 - avg_dev * 1.5))

    logger.info(
        "physics.estimate liters=%.3f co2=%.2fkg pm25=%.3fg conf=%.2f [vehicle=%s]",
        liters, co2, pm25 * 1000, confidence, vehicle.display_name,
    )

    return {
        "liters": round(liters, 3),
        "co2_kg": round(co2, 3),
        "pm25_g": round(pm25, 4),
        "confidence": round(confidence, 2),
        "breakdown": {
            "base_liters": round(base_liters, 3),
            "altitude_factor": round(altitude_factor, 3),
            "grade_factor": round(grade_factor, 3),
            "traffic_factor": round(traffic_factor, 3),
            "ac_factor": round(ac_factor, 3),
            "wind_factor": round(wind_factor, 3),
            "style_factor": round(style_factor, 3),
            "speed_factor": round(speed_factor, 3),
            "passenger_factor": round(passenger_factor, 3),
        },
    }


def _electric_estimate(
    distance_km: float, vehicle: VehicleProfile,
    avg_speed_kmh: float, avg_grade_pct: float
) -> dict:
    """Estimación para EV: kWh en vez de litros."""
    # Consumo típico EV urbano: 15 kWh/100km; ~18-20 kWh/100km con pendientes
    base_kwh_per_100km = 16.0
    grade_factor = 1.0 + abs(avg_grade_pct) * 0.05
    kwh = distance_km * base_kwh_per_100km / 100 * grade_factor
    logger.info("physics.electric kwh=%.2f km=%.2f grade=%.2f vehicle=%s",
                kwh, distance_km, avg_grade_pct, vehicle.display_name)
    return {
        "liters": 0.0,
        "kwh": round(kwh, 2),
        "co2_kg": round(kwh * 0.45, 3),  # factor CFE México 2025
        "pm25_g": 0.0,
        "confidence": 0.70,
        "breakdown": {"base_kwh": round(kwh, 2), "grade_factor": round(grade_factor, 3)},
    }


def _speed_efficiency_curve(speed_kmh: float) -> float:
    """
    Curva de eficiencia: consumo mínimo ~80 km/h.
    Penaliza velocidades muy bajas (<20) y muy altas (>100).
    """
    if speed_kmh <= 0:
        return 1.30
    if speed_kmh < 20:
        # Stop-and-go urbano: +20-30%
        return 1.25 - (speed_kmh / 20) * 0.15  # 1.25 @ 0 → 1.10 @ 20
    if speed_kmh <= 80:
        # Zona óptima descendente
        return 1.10 - (speed_kmh - 20) / 60 * 0.10  # 1.10 @ 20 → 1.00 @ 80
    if speed_kmh <= 120:
        # Aerodinámica penaliza
        return 1.00 + (speed_kmh - 80) / 40 * 0.15  # 1.00 @ 80 → 1.15 @ 120
    return 1.25  # >120 km/h


# ── Precios gasolina (default, sobrescritos por Profeco en Fase 3) ──────────
DEFAULT_FUEL_PRICES_MXN_PER_L = {
    FuelType.MAGNA: 23.80,
    FuelType.PREMIUM: 28.42,
    FuelType.DIESEL: 28.28,
    FuelType.HYBRID: 23.80,
    FuelType.ELECTRIC: 0.0,      # kWh precio aparte
}


def estimate_pesos_cost(liters: float, fuel_type: FuelType, price_per_l: float = None) -> float:
    """Calcula costo en MXN."""
    if price_per_l is None:
        price_per_l = DEFAULT_FUEL_PRICES_MXN_PER_L.get(fuel_type, 23.80)
    return round(liters * price_per_l, 2)
