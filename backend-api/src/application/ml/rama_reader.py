"""
Lector universal de archivos RAMA (SIMAT).

Maneja ambos formatos que devuelve CDMX:
- gzip real (años 2015-2021)  → magic bytes 1F 8B
- zip con extensión .gz engañosa (años 2022+) → magic bytes PK\\x03\\x04

Ambos casos contienen un CSV con el mismo schema:

    date,id_station,id_parameter,value,unit
    01/01/2021 01:00,ACO,CO,,15
    01/01/2021 01:00,ACO,O3,25,1

Donde:
- date: "DD/MM/YYYY HH:MM" (formato mexicano, día primero)
- id_parameter: O3, PM10, PM25, NO2, NO, NOX, SO2, CO, CO2, PM2.5, PMCO
- value: número o vacío (nulo)
- unit: código numérico (1=ppb, 2=µg/m³, 15=ppm)
"""
from __future__ import annotations

import gzip
import io
import zipfile
from pathlib import Path

import pandas as pd


# Líneas de metadatos antes del CSV real
METADATA_SKIP = 10


def detect_format(path: Path) -> str:
    """Devuelve 'gzip', 'zip' o 'unknown' según magic bytes."""
    with path.open("rb") as f:
        magic = f.read(4)
    if magic[:2] == b"\x1f\x8b":
        return "gzip"
    if magic[:4] == b"PK\x03\x04":
        return "zip"
    return "unknown"


def open_rama_csv(path: Path) -> io.TextIOBase:
    """Abre el archivo RAMA y devuelve un handle de texto listo para leer el CSV."""
    fmt = detect_format(path)

    if fmt == "gzip":
        return gzip.open(path, "rt", encoding="latin-1", errors="replace")

    if fmt == "zip":
        zf = zipfile.ZipFile(path)
        # Tomamos el primer CSV dentro del zip
        csv_name = next((n for n in zf.namelist() if n.lower().endswith(".csv")), None)
        if csv_name is None:
            csv_name = zf.namelist()[0]
        # Extrae a memoria
        raw = zf.read(csv_name)
        try:
            text = raw.decode("latin-1")
        except UnicodeDecodeError:
            text = raw.decode("utf-8", errors="replace")
        return io.StringIO(text)

    raise ValueError(f"Formato desconocido para {path.name}: magic={fmt}")


def read_rama_year(path: Path) -> pd.DataFrame:
    """
    Carga un archivo RAMA anual y devuelve un DataFrame normalizado con columnas:

        timestamp (datetime), station (str), parameter (str), value (float), unit (str)

    Devuelve DataFrame vacío si no se puede leer.
    """
    if not path.exists():
        return pd.DataFrame()

    try:
        with open_rama_csv(path) as handle:
            df = pd.read_csv(
                handle,
                skiprows=METADATA_SKIP,
                low_memory=False,
                dtype={"value": "float64"},
            )
    except Exception as exc:
        print(f"[rama_reader] error leyendo {path.name}: {exc}")
        return pd.DataFrame()

    # Normalización de columnas
    df.columns = [c.strip().lower() for c in df.columns]

    # Si el header real no fue la línea 11, scan para el header correcto
    if "date" not in df.columns or "id_parameter" not in df.columns:
        # Reintentar con diferente skip
        for alt_skip in [0, 5, 8, 9, 11, 12, 15]:
            try:
                with open_rama_csv(path) as handle:
                    df_try = pd.read_csv(handle, skiprows=alt_skip, low_memory=False)
                df_try.columns = [c.strip().lower() for c in df_try.columns]
                if "date" in df_try.columns and "id_parameter" in df_try.columns:
                    df = df_try
                    break
            except Exception:
                continue

    if "date" not in df.columns or "id_parameter" not in df.columns:
        print(f"[rama_reader] {path.name}: no se encontró header — columnas: {list(df.columns)}")
        return pd.DataFrame()

    # Parse del timestamp "DD/MM/YYYY HH:MM"
    df["timestamp"] = pd.to_datetime(df["date"], format="%d/%m/%Y %H:%M", errors="coerce")

    # Fallback para formatos alternativos (ISO, MM/DD/YYYY, etc.)
    mask_na = df["timestamp"].isna()
    if mask_na.any():
        import warnings
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            df.loc[mask_na, "timestamp"] = pd.to_datetime(
                df.loc[mask_na, "date"], errors="coerce", dayfirst=True
            )

    # Normalizar valor
    df["value"] = pd.to_numeric(df["value"], errors="coerce")
    df["id_parameter"] = df["id_parameter"].astype(str).str.upper().str.replace(".", "", regex=False)

    # Mapeo de parameter → nombre canónico
    df["parameter"] = df["id_parameter"].replace({
        "PM25": "PM25",
        "PM2.5": "PM25",
        "PM10": "PM10",
        "O3": "O3",
        "NO2": "NO2",
        "NO": "NO",
        "NOX": "NOX",
        "SO2": "SO2",
        "CO": "CO",
        "CO2": "CO2",
        "PMCO": "PMCO",
        "H2S": "H2S",
    })

    # Renombrar estación
    if "id_station" in df.columns:
        df["station"] = df["id_station"].astype(str).str.upper()
    elif "cve_estac" in df.columns:
        df["station"] = df["cve_estac"].astype(str).str.upper()

    # Limpiar
    df = df.dropna(subset=["timestamp", "value"])
    df = df[df["value"] >= 0]   # RAMA a veces mete -99 como flag de missing

    cols_out = ["timestamp", "station", "parameter", "value"]
    if "unit" in df.columns:
        df["unit"] = df["unit"].astype(str)
        cols_out.append("unit")

    return df[cols_out].reset_index(drop=True)
