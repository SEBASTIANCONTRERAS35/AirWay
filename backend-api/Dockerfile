FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Dependencias de GeoDjango/psycopg + libgomp1 (requerido por XGBoost en Linux)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc g++ \
    gdal-bin libgdal-dev \
    proj-bin libproj-dev \
    geos-bin libgeos-dev \
    postgresql-client \
    libgomp1 \
    curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV GDAL_DATA=/usr/share/gdal \
    PROJ_LIB=/usr/share/proj \
    PYTHONPATH=/app/src \
    DJANGO_SETTINGS_MODULE=core.settings

EXPOSE 8000

# Render asigna el puerto en $PORT (default 10000). Usamos $PORT con fallback.
CMD sh -c "cd /app/src && gunicorn core.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 2 --timeout 120"
