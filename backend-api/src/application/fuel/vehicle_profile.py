"""
VehicleProfile: perfil de vehículo del usuario para estimación de combustible.

Datos base: catálogo CONUEE rendimiento vehículos ligeros venta México.
Ajustes locales: altitud CDMX, estilo de conducción, mantenimiento.
"""
from dataclasses import dataclass, field, asdict
from enum import Enum
from typing import Optional


class FuelType(str, Enum):
    MAGNA = "magna"       # 87 octanos
    PREMIUM = "premium"   # 93 octanos
    DIESEL = "diesel"
    HYBRID = "hybrid"
    ELECTRIC = "electric"


@dataclass
class VehicleProfile:
    """Perfil único por usuario. Persistido en iOS UserDefaults + backend (opcional)."""
    make: str                         # "Chevrolet"
    model: str                        # "Aveo"
    year: int                         # 2018
    fuel_type: FuelType = FuelType.MAGNA
    conuee_km_per_l: float = 14.0     # CONUEE catalog. Default conservador urbano.
    engine_cc: int = 1600
    transmission: str = "manual"      # "manual" | "automatic" | "cvt"
    weight_kg: int = 1150
    drag_coefficient: float = 0.33
    driving_style: float = 1.0        # 0.85 (suave) .. 1.25 (agresivo); actualizado por EMA
    nickname: Optional[str] = None
    odometer_km: Optional[int] = None

    @classmethod
    def from_dict(cls, d: dict) -> "VehicleProfile":
        """Construye desde payload JSON. Tolerante a campos faltantes."""
        ft = d.get("fuel_type", "magna")
        if isinstance(ft, str):
            ft = FuelType(ft)
        return cls(
            make=d["make"],
            model=d["model"],
            year=int(d["year"]),
            fuel_type=ft,
            conuee_km_per_l=float(d.get("conuee_km_per_l", 14.0)),
            engine_cc=int(d.get("engine_cc", 1600)),
            transmission=d.get("transmission", "manual"),
            weight_kg=int(d.get("weight_kg", 1150)),
            drag_coefficient=float(d.get("drag_coefficient", 0.33)),
            driving_style=float(d.get("driving_style", 1.0)),
            nickname=d.get("nickname"),
            odometer_km=d.get("odometer_km"),
        )

    def to_dict(self) -> dict:
        d = asdict(self)
        d["fuel_type"] = self.fuel_type.value
        return d

    @property
    def display_name(self) -> str:
        return f"{self.make} {self.model} {self.year}"

    @property
    def is_electric(self) -> bool:
        return self.fuel_type == FuelType.ELECTRIC

    @property
    def is_diesel(self) -> bool:
        return self.fuel_type == FuelType.DIESEL
