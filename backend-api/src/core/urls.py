from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include("interfaces.api.routes.urls")),
    path('api/v1/', include("interfaces.api.ppi.urls")),
    path('api/v1/', include("interfaces.api.contingency.urls")),
    path('api/v1/', include("interfaces.api.fuel.urls")),
    path('api/v1/', include("interfaces.api.trip.urls")),
    path('healthz', include("interfaces.api.routes.urls"))
]
