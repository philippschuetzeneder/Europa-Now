#!/usr/bin/env python3
"""Optional helper: downloads Natural Earth GeoJSON for the Europe map prototype.

The game loads GeoJSON directly at runtime, so running this script is not required
if res://data/ne_110m_admin_0_countries.geojson is already present.

Data source (public domain):
https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/
"""

from __future__ import annotations

import urllib.request
from pathlib import Path

URL = (
	"https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/"
	"geojson/ne_110m_admin_0_countries.geojson"
)
OUTPUT = Path(__file__).resolve().parents[1] / "data" / "ne_110m_admin_0_countries.geojson"


def main() -> None:
	OUTPUT.parent.mkdir(parents=True, exist_ok=True)
	print(f"Downloading {URL} ...")
	urllib.request.urlretrieve(URL, OUTPUT)
	print(f"Saved to {OUTPUT}")


if __name__ == "__main__":
	main()
