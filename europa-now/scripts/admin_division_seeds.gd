class_name AdminDivisionSeeds
extends RefCounted

## Hardcoded administrative division seeds (lon/lat WGS84) for selected countries.


static func seeds_for_country(country_id: String) -> Array[Dictionary]:
	match country_id:
		"AUT":
			return _from_entries(AUSTRIA)
		"DEU":
			return _from_entries(GERMANY)
		"USA":
			return _from_entries(USA_STATES)
		_:
			return []


static func has_admin_divisions(country_id: String) -> bool:
	return country_id in ["AUT", "DEU", "USA"]


static func division_count(country_id: String) -> int:
	return seeds_for_country(country_id).size()


const AUSTRIA: Array[Dictionary] = [
	{"slug": "wien", "name": "Wien", "lon": 16.37, "lat": 48.21},
	{"slug": "niederoesterreich", "name": "Niederösterreich", "lon": 15.55, "lat": 48.30},
	{"slug": "oberoesterreich", "name": "Oberösterreich", "lon": 14.10, "lat": 48.20},
	{"slug": "steiermark", "name": "Steiermark", "lon": 15.20, "lat": 47.35},
	{"slug": "kaernten", "name": "Kärnten", "lon": 14.10, "lat": 46.75},
	{"slug": "salzburg", "name": "Salzburg", "lon": 13.05, "lat": 47.70},
	{"slug": "tirol", "name": "Tirol", "lon": 11.40, "lat": 47.10},
	{"slug": "vorarlberg", "name": "Vorarlberg", "lon": 9.90, "lat": 47.20},
	{"slug": "burgenland", "name": "Burgenland", "lon": 16.45, "lat": 47.55},
]

const GERMANY: Array[Dictionary] = [
	{"slug": "bw", "name": "Baden-Württemberg", "lon": 9.18, "lat": 48.78},
	{"slug": "by", "name": "Bayern", "lon": 11.58, "lat": 48.14},
	{"slug": "be", "name": "Berlin", "lon": 13.40, "lat": 52.52},
	{"slug": "bb", "name": "Brandenburg", "lon": 13.06, "lat": 52.40},
	{"slug": "hb", "name": "Bremen", "lon": 8.80, "lat": 53.08},
	{"slug": "hh", "name": "Hamburg", "lon": 9.99, "lat": 53.55},
	{"slug": "he", "name": "Hessen", "lon": 8.24, "lat": 50.08},
	{"slug": "mv", "name": "Mecklenburg-Vorpommern", "lon": 12.43, "lat": 53.79},
	{"slug": "ni", "name": "Niedersachsen", "lon": 9.73, "lat": 52.37},
	{"slug": "nw", "name": "Nordrhein-Westfalen", "lon": 7.47, "lat": 51.51},
	{"slug": "rp", "name": "Rheinland-Pfalz", "lon": 7.45, "lat": 49.91},
	{"slug": "sl", "name": "Saarland", "lon": 7.00, "lat": 49.23},
	{"slug": "sn", "name": "Sachsen", "lon": 13.74, "lat": 51.05},
	{"slug": "st", "name": "Sachsen-Anhalt", "lon": 11.63, "lat": 52.12},
	{"slug": "sh", "name": "Schleswig-Holstein", "lon": 10.12, "lat": 54.32},
	{"slug": "th", "name": "Thüringen", "lon": 11.03, "lat": 50.98},
]

const USA_STATES: Array[Dictionary] = [
	{"slug": "al", "name": "Alabama", "lon": -86.79, "lat": 32.36},
	{"slug": "ak", "name": "Alaska", "lon": -152.40, "lat": 64.20},
	{"slug": "az", "name": "Arizona", "lon": -111.66, "lat": 34.27},
	{"slug": "ar", "name": "Arkansas", "lon": -92.37, "lat": 34.75},
	{"slug": "ca", "name": "Kalifornien", "lon": -119.42, "lat": 36.78},
	{"slug": "co", "name": "Colorado", "lon": -105.55, "lat": 39.00},
	{"slug": "ct", "name": "Connecticut", "lon": -72.67, "lat": 41.60},
	{"slug": "de", "name": "Delaware", "lon": -75.53, "lat": 39.16},
	{"slug": "fl", "name": "Florida", "lon": -81.52, "lat": 27.77},
	{"slug": "ga", "name": "Georgia", "lon": -83.44, "lat": 32.64},
	{"slug": "hi", "name": "Hawaii", "lon": -157.50, "lat": 21.09},
	{"slug": "id", "name": "Idaho", "lon": -114.74, "lat": 44.07},
	{"slug": "il", "name": "Illinois", "lon": -89.40, "lat": 40.01},
	{"slug": "in", "name": "Indiana", "lon": -86.13, "lat": 40.27},
	{"slug": "ia", "name": "Iowa", "lon": -93.21, "lat": 41.88},
	{"slug": "ks", "name": "Kansas", "lon": -98.48, "lat": 38.50},
	{"slug": "ky", "name": "Kentucky", "lon": -84.27, "lat": 37.84},
	{"slug": "la", "name": "Louisiana", "lon": -91.96, "lat": 30.98},
	{"slug": "me", "name": "Maine", "lon": -69.24, "lat": 45.37},
	{"slug": "md", "name": "Maryland", "lon": -76.64, "lat": 39.05},
	{"slug": "ma", "name": "Massachusetts", "lon": -71.53, "lat": 42.26},
	{"slug": "mi", "name": "Michigan", "lon": -84.54, "lat": 44.31},
	{"slug": "mn", "name": "Minnesota", "lon": -94.69, "lat": 46.73},
	{"slug": "ms", "name": "Mississippi", "lon": -89.68, "lat": 32.74},
	{"slug": "mo", "name": "Missouri", "lon": -92.29, "lat": 38.46},
	{"slug": "mt", "name": "Montana", "lon": -110.45, "lat": 46.88},
	{"slug": "ne", "name": "Nebraska", "lon": -99.90, "lat": 41.49},
	{"slug": "nv", "name": "Nevada", "lon": -116.42, "lat": 39.33},
	{"slug": "nh", "name": "New Hampshire", "lon": -71.57, "lat": 43.19},
	{"slug": "nj", "name": "New Jersey", "lon": -74.52, "lat": 40.06},
	{"slug": "nm", "name": "New Mexico", "lon": -106.02, "lat": 34.52},
	{"slug": "ny", "name": "New York", "lon": -75.50, "lat": 43.00},
	{"slug": "nc", "name": "North Carolina", "lon": -79.02, "lat": 35.76},
	{"slug": "nd", "name": "North Dakota", "lon": -100.47, "lat": 47.55},
	{"slug": "oh", "name": "Ohio", "lon": -82.76, "lat": 40.42},
	{"slug": "ok", "name": "Oklahoma", "lon": -97.52, "lat": 35.47},
	{"slug": "or", "name": "Oregon", "lon": -120.55, "lat": 43.80},
	{"slug": "pa", "name": "Pennsylvania", "lon": -77.19, "lat": 40.88},
	{"slug": "ri", "name": "Rhode Island", "lon": -71.48, "lat": 41.68},
	{"slug": "sc", "name": "South Carolina", "lon": -80.90, "lat": 33.84},
	{"slug": "sd", "name": "South Dakota", "lon": -100.35, "lat": 44.44},
	{"slug": "tn", "name": "Tennessee", "lon": -86.58, "lat": 35.86},
	{"slug": "tx", "name": "Texas", "lon": -99.90, "lat": 31.97},
	{"slug": "ut", "name": "Utah", "lon": -111.67, "lat": 39.32},
	{"slug": "vt", "name": "Vermont", "lon": -72.58, "lat": 44.05},
	{"slug": "va", "name": "Virginia", "lon": -78.66, "lat": 37.43},
	{"slug": "wa", "name": "Washington", "lon": -120.74, "lat": 47.75},
	{"slug": "wv", "name": "West Virginia", "lon": -80.62, "lat": 38.64},
	{"slug": "wi", "name": "Wisconsin", "lon": -89.62, "lat": 44.62},
	{"slug": "wy", "name": "Wyoming", "lon": -107.55, "lat": 43.08},
]


static func _from_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	var seeds: Array[Dictionary] = []
	for entry in entries:
		seeds.append({
			"slug": entry["slug"],
			"name": entry["name"],
			"position": GeoProjection.project(float(entry["lon"]), float(entry["lat"])),
		})
	return seeds
