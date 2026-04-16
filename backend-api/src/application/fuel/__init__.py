"""Fuel consumption estimation module for AirWay."""
from .vehicle_profile import VehicleProfile, FuelType
from .physics_model import estimate_fuel_liters
from .fuel_service import FuelService

__all__ = ["VehicleProfile", "FuelType", "estimate_fuel_liters", "FuelService"]
