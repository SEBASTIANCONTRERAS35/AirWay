from datetime import datetime

class DummyGridProvider:
    """
    Devuelve un AQI fijo (80) para cualquier punto/instante.
    Luego lo sustituiremos por TEMPO+OpenAQ+IMERG+MERRA.
    """
    def get_aqi_cell(self, lat: float, lon: float, when: datetime) -> dict:
        return {"aqi": 80, "ai": 0.1, "pm25": 15, "o3": 50, "no2": 30, "rain": 0.0, "pbl": 800.0, "wind": {"u":0.0,"v":0.0}}