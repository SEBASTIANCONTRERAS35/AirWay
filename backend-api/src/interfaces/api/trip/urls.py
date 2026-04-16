"""URLs del módulo trip (multimodal)."""
from django.urls import path
from .views import TripCompareView

urlpatterns = [
    path("trip/compare", TripCompareView.as_view(), name="trip-compare"),
]
