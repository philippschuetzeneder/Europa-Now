class_name CountryMetadata
extends RefCounted

## Country metadata for the 2022 prototype. Keys use ISO-A3 (ADM0_A3) like the map data.
const DATA: Dictionary = {
	"AND": {"capital": "Andorra la Vella", "lon": 1.5218, "lat": 42.5063, "head_of_state": "Joan Enric Vives i Sicilia", "government": "Parlamentarische Monarchie"},
	"ALB": {"capital": "Tirana", "lon": 19.8187, "lat": 41.3275, "head_of_state": "Ilir Meta", "government": "Parlamentarische Republik"},
	"ARM": {"capital": "Jerewan", "lon": 44.5152, "lat": 40.1792, "head_of_state": "Armen Sarkissian", "government": "Parlamentarische Republik"},
	"AUT": {"capital": "Wien", "lon": 16.3738, "lat": 48.2082, "head_of_state": "Alexander Van der Bellen", "government": "Parlamentarische Republik"},
	"AZE": {"capital": "Baku", "lon": 49.8671, "lat": 40.4093, "head_of_state": "Ilham Alijew", "government": "Praesidentielle Republik"},
	"BIH": {"capital": "Sarajevo", "lon": 18.4131, "lat": 43.8563, "head_of_state": "Vorsitz des Praesidiums", "government": "Parlamentarische Republik"},
	"BEL": {"capital": "Bruessel", "lon": 4.3517, "lat": 50.8503, "head_of_state": "Philippe", "government": "Konstitutionelle Monarchie"},
	"BGR": {"capital": "Sofia", "lon": 23.3219, "lat": 42.6977, "head_of_state": "Rumen Radev", "government": "Parlamentarische Republik"},
	"BLR": {"capital": "Minsk", "lon": 27.5615, "lat": 53.9045, "head_of_state": "Alexander Lukaschenko", "government": "Autoritaeres Regime"},
	"CHE": {"capital": "Bern", "lon": 7.4474, "lat": 46.9480, "head_of_state": "Bundesrat", "government": "Direkte Demokratie / Bundesstaat"},
	"CYP": {"capital": "Nikosia", "lon": 33.3823, "lat": 35.1856, "head_of_state": "Nikos Anastasiades", "government": "Praesidentielle Republik"},
	"CZE": {"capital": "Prag", "lon": 14.4378, "lat": 50.0755, "head_of_state": "Miloš Zeman", "government": "Parlamentarische Republik"},
	"DEU": {"capital": "Berlin", "lon": 13.4050, "lat": 52.5200, "head_of_state": "Frank-Walter Steinmeier", "government": "Parlamentarische Demokratie"},
	"DNK": {"capital": "Kopenhagen", "lon": 12.5683, "lat": 55.6761, "head_of_state": "Margrethe II.", "government": "Parlamentarische Monarchie"},
	"ESP": {"capital": "Madrid", "lon": -3.7038, "lat": 40.4168, "head_of_state": "Felipe VI.", "government": "Parlamentarische Monarchie"},
	"EST": {"capital": "Tallinn", "lon": 24.7536, "lat": 59.4370, "head_of_state": "Kersti Kaljulaid", "government": "Parlamentarische Republik"},
	"FIN": {"capital": "Helsinki", "lon": 24.9384, "lat": 60.1699, "head_of_state": "Sauli Niinistö", "government": "Parlamentarische Republik"},
	"FRA": {"capital": "Paris", "lon": 2.3522, "lat": 48.8566, "head_of_state": "Emmanuel Macron", "government": "Semipraesidentielle Republik"},
	"GBR": {"capital": "London", "lon": -0.1276, "lat": 51.5072, "head_of_state": "Elizabeth II.", "government": "Parlamentarische Monarchie"},
	"GEO": {"capital": "Tiflis", "lon": 44.7930, "lat": 41.7151, "head_of_state": "Salome Zurabishvili", "government": "Semipraesidentielle Republik"},
	"GRC": {"capital": "Athen", "lon": 23.7275, "lat": 37.9838, "head_of_state": "Katerina Sakellaropoulou", "government": "Parlamentarische Republik"},
	"HRV": {"capital": "Zagreb", "lon": 15.9819, "lat": 45.8150, "head_of_state": "Zoran Milanovic", "government": "Parlamentarische Republik"},
	"HUN": {"capital": "Budapest", "lon": 19.0402, "lat": 47.4979, "head_of_state": "Janos Ader", "government": "Parlamentarische Republik"},
	"IRL": {"capital": "Dublin", "lon": -6.2603, "lat": 53.3498, "head_of_state": "Michael D. Higgins", "government": "Parlamentarische Republik"},
	"ISL": {"capital": "Reykjavik", "lon": -21.9426, "lat": 64.1466, "head_of_state": "Gudni Thorlacius Johannesson", "government": "Parlamentarische Republik"},
	"ITA": {"capital": "Rom", "lon": 12.4964, "lat": 41.9028, "head_of_state": "Sergio Mattarella", "government": "Parlamentarische Republik"},
	"KAZ": {"capital": "Astana", "lon": 71.4306, "lat": 51.1605, "head_of_state": "Kassym-Schomart Tokajew", "government": "Praesidentielle Republik"},
	"KOS": {"capital": "Pristina", "lon": 21.1655, "lat": 42.6629, "head_of_state": "Vjosa Osmani", "government": "Parlamentarische Republik"},
	"LIE": {"capital": "Vaduz", "lon": 9.5215, "lat": 47.1410, "head_of_state": "Hans-Adam II.", "government": "Konstitutionelle Monarchie"},
	"LTU": {"capital": "Vilnius", "lon": 25.2797, "lat": 54.6872, "head_of_state": "Gitanas Nauseda", "government": "Semipraesidentielle Republik"},
	"LUX": {"capital": "Luxemburg", "lon": 6.1319, "lat": 49.6116, "head_of_state": "Henri", "government": "Konstitutionelle Monarchie"},
	"LVA": {"capital": "Riga", "lon": 24.1052, "lat": 56.9496, "head_of_state": "Egils Levits", "government": "Parlamentarische Republik"},
	"MCO": {"capital": "Monaco", "lon": 7.4246, "lat": 43.7384, "head_of_state": "Albert II.", "government": "Konstitutionelle Monarchie"},
	"MDA": {"capital": "Chisinau", "lon": 28.8638, "lat": 47.0105, "head_of_state": "Maia Sandu", "government": "Parlamentarische Republik"},
	"MKD": {"capital": "Skopje", "lon": 21.4254, "lat": 41.9981, "head_of_state": "Stevo Pendarovski", "government": "Parlamentarische Republik"},
	"MLT": {"capital": "Valletta", "lon": 14.5146, "lat": 35.8989, "head_of_state": "George Vella", "government": "Parlamentarische Republik"},
	"MNE": {"capital": "Podgorica", "lon": 19.2594, "lat": 42.4304, "head_of_state": "Milo Djukanovic", "government": "Parlamentarische Republik"},
	"NLD": {"capital": "Amsterdam", "lon": 4.9041, "lat": 52.3676, "head_of_state": "Willem-Alexander", "government": "Parlamentarische Monarchie"},
	"NOR": {"capital": "Oslo", "lon": 10.7522, "lat": 59.9139, "head_of_state": "Harald V.", "government": "Parlamentarische Monarchie"},
	"POL": {"capital": "Warschau", "lon": 21.0122, "lat": 52.2297, "head_of_state": "Andrzej Duda", "government": "Parlamentarische Republik"},
	"PRT": {"capital": "Lissabon", "lon": -9.1393, "lat": 38.7223, "head_of_state": "Marcelo Rebelo de Sousa", "government": "Semipraesidentielle Republik"},
	"ROU": {"capital": "Bukarest", "lon": 26.1025, "lat": 44.4268, "head_of_state": "Klaus Iohannis", "government": "Semipraesidentielle Republik"},
	"RUS": {"capital": "Moskau", "lon": 37.6173, "lat": 55.7558, "head_of_state": "Wladimir Putin", "government": "Praesidentielle Foederation"},
	"SRB": {"capital": "Belgrad", "lon": 20.4489, "lat": 44.7866, "head_of_state": "Aleksandar Vucic", "government": "Parlamentarische Republik"},
	"SVK": {"capital": "Bratislava", "lon": 17.1077, "lat": 48.1486, "head_of_state": "Zuzana Caputova", "government": "Parlamentarische Republik"},
	"SVN": {"capital": "Ljubljana", "lon": 14.5058, "lat": 46.0569, "head_of_state": "Borut Pahor", "government": "Parlamentarische Republik"},
	"SWE": {"capital": "Stockholm", "lon": 18.0686, "lat": 59.3293, "head_of_state": "Carl XVI. Gustaf", "government": "Parlamentarische Monarchie"},
	"TUR": {"capital": "Ankara", "lon": 32.8597, "lat": 39.9334, "head_of_state": "Recep Tayyip Erdogan", "government": "Praesidentielle Republik"},
	"UKR": {"capital": "Kiew", "lon": 30.5234, "lat": 50.4501, "head_of_state": "Wolodymyr Selenskyj", "government": "Semipraesidentielle Republik"},
	"VAT": {"capital": "Vatikanstadt", "lon": 12.4534, "lat": 41.9029, "head_of_state": "Papst Franziskus", "government": "Theokratische Monarchie"},
	"SMR": {"capital": "San Marino", "lon": 12.4578, "lat": 43.9424, "head_of_state": "Zwei Captains Regent", "government": "Parlamentarische Republik"},
}


static func enrich_country_data(data: Dictionary) -> Dictionary:
	var country_id := str(data.get("id", ""))
	var meta: Dictionary = DATA.get(country_id, {})
	if meta.is_empty():
		push_warning("Missing metadata for country: %s" % country_id)

	data["capital_name"] = str(meta.get("capital", "k. A."))
	data["capital_position"] = GeoProjection.project(
		float(meta.get("lon", 0.0)),
		float(meta.get("lat", 0.0))
	)
	data["head_of_state"] = str(meta.get("head_of_state", "k. A."))
	data["government_type"] = str(meta.get("government", "k. A."))
	return data
