# backend/interfaces/api/routes/urls.py
from django.urls import path
from .views import OptimalRouteView, CurrentAQIView, HealthCheckView

urlpatterns = [
    path("routes/optimal", OptimalRouteView.as_view(), name="routes-optimal"),
    path("air/current", CurrentAQIView.as_view(), name="air-current"),
    path("healthz", HealthCheckView.as_view(), name="health-check"),
]
