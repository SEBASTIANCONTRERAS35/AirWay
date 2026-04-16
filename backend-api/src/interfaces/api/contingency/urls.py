# backend/interfaces/api/contingency/urls.py
from django.urls import path

from .views import ContingencyForecastView, ContingencyHealthView

urlpatterns = [
    path("contingency/forecast", ContingencyForecastView.as_view(), name="contingency-forecast"),
    path("contingency/health", ContingencyHealthView.as_view(), name="contingency-health"),
]
