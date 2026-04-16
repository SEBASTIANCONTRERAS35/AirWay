"""URLs del módulo GasolinaMeter."""
from django.urls import path
from .views import (
    FuelEstimateView,
    FuelCatalogView,
    FuelCatalogSearchView,
    FuelPricesView,
)
from .stations_view import StationsOnRouteView, StationsNearPointView
from .vehicle_vision_view import VehicleVisionView
from .departure_view import OptimalDepartureView

urlpatterns = [
    path("fuel/estimate", FuelEstimateView.as_view(), name="fuel-estimate"),
    path("fuel/catalog", FuelCatalogView.as_view(), name="fuel-catalog"),
    path("fuel/catalog/search", FuelCatalogSearchView.as_view(), name="fuel-catalog-search"),
    path("fuel/prices", FuelPricesView.as_view(), name="fuel-prices"),
    path("fuel/stations_on_route", StationsOnRouteView.as_view(), name="fuel-stations-route"),
    path("fuel/stations_near", StationsNearPointView.as_view(), name="fuel-stations-near"),
    path("fuel/optimal_departure", OptimalDepartureView.as_view(), name="fuel-optimal-departure"),
    path("vehicle/identify_from_image", VehicleVisionView.as_view(), name="vehicle-vision"),
]
