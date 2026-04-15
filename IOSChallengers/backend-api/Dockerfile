FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Dependencias de GeoDjango/psycopg
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc g++ \
    gdal-bin libgdal-dev \
    proj-bin libproj-dev \
    geos-bin libgeos-dev \
    postgresql-client \
    curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV GDAL_DATA=/usr/share/gdal \
    PROJ_LIB=/usr/share/proj

EXPOSE 8000
