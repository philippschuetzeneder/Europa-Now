class_name FlagFactory
extends RefCounted

const WIDTH := 40
const HEIGHT := 28
const FLAGS_DIR := "res://data/flags/"

static var _cache: Dictionary = {}
static var _missing_logged: Dictionary = {}


static func get_placeholder_texture() -> Texture2D:
	if _cache.has("__placeholder__"):
		return _cache["__placeholder__"]
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.28, 0.32, 0.38, 1.0))
	var texture := ImageTexture.create_from_image(image)
	_cache["__placeholder__"] = texture
	return texture


static func get_flag_texture(country: Country) -> Texture2D:
	var code := _resolve_code(country)
	if code.is_empty():
		return get_placeholder_texture()
	if _cache.has(code):
		return _cache[code]

	var texture := _load_flag_image(code)
	if texture == null:
		texture = _build_flag(code)
	if texture == null:
		texture = get_placeholder_texture()

	_cache[code] = texture
	return texture


static func _load_flag_image(code: String) -> Texture2D:
	var path := "%s%s.png" % [FLAGS_DIR, code.to_lower()]
	if not ResourceLoader.exists(path):
		if not _missing_logged.has(code):
			_missing_logged[code] = true
		return null

	var image := Image.new()
	var load_error := image.load(ProjectSettings.globalize_path(path))
	if load_error != OK or image.is_empty():
		return null

	image.resize(WIDTH, HEIGHT, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(image)


static func _resolve_code(country: Country) -> String:
	var code := country.iso_a2.strip_edges().to_upper()
	if code.length() == 2 and code != "-9" and not code.contains("9"):
		return code
	return _iso_a3_to_a2(country.country_id)


static func _iso_a3_to_a2(iso_a3: String) -> String:
	match iso_a3.to_upper():
		"DEU": return "DE"
		"FRA": return "FR"
		"GBR": return "GB"
		"KOS": return "XK"
		"RUS": return "RU"
		"UKR": return "UA"
		"CZE": return "CZ"
		"GRC": return "GR"
		"SVK": return "SK"
		"SVN": return "SI"
		"BIH": return "BA"
		"MKD": return "MK"
		"MDA": return "MD"
		"BLR": return "BY"
		"CHE": return "CH"
		"AUT": return "AT"
		"NLD": return "NL"
		"BEL": return "BE"
		"DNK": return "DK"
		"SWE": return "SE"
		"NOR": return "NO"
		"FIN": return "FI"
		"POL": return "PL"
		"ITA": return "IT"
		"ESP": return "ES"
		"PRT": return "PT"
		"IRL": return "IE"
		"ISL": return "IS"
		"TUR": return "TR"
		"HUN": return "HU"
		"ROU": return "RO"
		"BGR": return "BG"
		"HRV": return "HR"
		"SRB": return "RS"
		"MNE": return "ME"
		"ALB": return "AL"
		"EST": return "EE"
		"LVA": return "LV"
		"LTU": return "LT"
		"LUX": return "LU"
		"MLT": return "MT"
		"CYP": return "CY"
		"AND": return "AD"
		"MCO": return "MC"
		"SMR": return "SM"
		"VAT": return "VA"
		"LIE": return "LI"
		"GEO": return "GE"
		"ARM": return "AM"
		"AZE": return "AZ"
		"KAZ": return "KZ"
		"USA": return "US"
		"CHN": return "CN"
		"IND": return "IN"
		"BRA": return "BR"
		"CAN": return "CA"
		"AUS": return "AU"
		"JPN": return "JP"
		"MEX": return "MX"
		"ZAF": return "ZA"
		"EGY": return "EG"
		"SAU": return "SA"
		"ARG": return "AR"
		"IDN": return "ID"
		"KOR": return "KR"
		"PRK": return "KP"
		"NGA": return "NG"
		"PAK": return "PK"
		"BGD": return "BD"
		"PHL": return "PH"
		"VNM": return "VN"
		"THA": return "TH"
		"IRN": return "IR"
		"IRQ": return "IQ"
		"ISR": return "IL"
		"NZL": return "NZ"
		"COL": return "CO"
		"CHL": return "CL"
		"PER": return "PE"
		"VEN": return "VE"
		"MYS": return "MY"
		"SGP": return "SG"
		"ARE": return "AE"
		"QAT": return "QA"
		"KWT": return "KW"
		"OMN": return "OM"
		"YEM": return "YE"
		"JOR": return "JO"
		"LBN": return "LB"
		"SYR": return "SY"
		"MAR": return "MA"
		"DZA": return "DZ"
		"TUN": return "TN"
		"LBY": return "LY"
		"KEN": return "KE"
		"ETH": return "ET"
		"TZA": return "TZ"
		"UGA": return "UG"
		"GHA": return "GH"
		"CIV": return "CI"
		"CMR": return "CM"
		"COD": return "CD"
		"COG": return "CG"
		"SDN": return "SD"
		"SSD": return "SS"
		"MOZ": return "MZ"
		"AGO": return "AO"
		"ZMB": return "ZM"
		"ZWE": return "ZW"
		"BWA": return "BW"
		"NAM": return "NA"
		"SEN": return "SN"
		"MLI": return "ML"
		"NER": return "NE"
		"TCD": return "TD"
		"CAF": return "CF"
		"SOM": return "SO"
		"RWA": return "RW"
		"BDI": return "BI"
		"MWI": return "MW"
		"MDG": return "MG"
		"MRT": return "MR"
		"GIN": return "GN"
		"GNB": return "GW"
		"SLE": return "SL"
		"LBR": return "LR"
		"TGO": return "TG"
		"BEN": return "BJ"
		"GMB": return "GM"
		"GAB": return "GA"
		"GNQ": return "GQ"
		"STP": return "ST"
		"CPV": return "CV"
		"COM": return "KM"
		"MUS": return "MU"
		"SYC": return "SC"
		"DJI": return "DJ"
		"ERI": return "ER"
		"SWZ": return "SZ"
		"LSO": return "LS"
		"AFG": return "AF"
		"NPL": return "NP"
		"LKA": return "LK"
		"MMR": return "MM"
		"KHM": return "KH"
		"LAO": return "LA"
		"MNG": return "MN"
		"UZB": return "UZ"
		"TKM": return "TM"
		"TJK": return "TJ"
		"KGZ": return "KG"
		"BTN": return "BT"
		"MDV": return "MV"
		"BRN": return "BN"
		"TLS": return "TL"
		"FJI": return "FJ"
		"PNG": return "PG"
		"SLB": return "SB"
		"VUT": return "VU"
		"WSM": return "WS"
		"TON": return "TO"
		"KIR": return "KI"
		"TUV": return "TV"
		"NRU": return "NR"
		"PLW": return "PW"
		"MHL": return "MH"
		"FSM": return "FM"
		"CUB": return "CU"
		"JAM": return "JM"
		"HTI": return "HT"
		"DOM": return "DO"
		"PRI": return "PR"
		"GTM": return "GT"
		"BLZ": return "BZ"
		"HND": return "HN"
		"SLV": return "SV"
		"NIC": return "NI"
		"CRI": return "CR"
		"PAN": return "PA"
		"ECU": return "EC"
		"BOL": return "BO"
		"PRY": return "PY"
		"URY": return "UY"
		"GUY": return "GY"
		"SUR": return "SR"
		"TWN": return "TW"
		"PSE": return "PS"
		"PSX": return "PS"
		"SAH": return "EH"
		"ESH": return "EH"
		"SOL": return "SO"
		_: return ""


static func _build_flag(code: String) -> Texture2D:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	var pattern: Dictionary = _PATTERNS.get(code, {})

	if pattern.is_empty():
		return null

	match str(pattern.get("type", "")):
		"h":
			_draw_horizontal_stripes(image, pattern.get("colors", []))
		"v":
			_draw_vertical_stripes(image, pattern.get("colors", []))
		"cross":
			_draw_cross_flag(image, pattern)
		"solid", _:
			image.fill(pattern.get("color", Color(0.28, 0.32, 0.38, 1.0)))

	return ImageTexture.create_from_image(image)


static func _draw_horizontal_stripes(image: Image, colors: Array) -> void:
	if colors.is_empty():
		return
	var stripe_height := float(HEIGHT) / float(colors.size())
	for i in colors.size():
		var y_start := int(round(i * stripe_height))
		var y_end := int(round((i + 1) * stripe_height)) - 1
		for y in range(y_start, y_end + 1):
			for x in WIDTH:
				image.set_pixel(x, y, colors[i])


static func _draw_vertical_stripes(image: Image, colors: Array) -> void:
	if colors.is_empty():
		return
	var stripe_width := float(WIDTH) / float(colors.size())
	for i in colors.size():
		var x_start := int(round(i * stripe_width))
		var x_end := int(round((i + 1) * stripe_width)) - 1
		for x in range(x_start, x_end + 1):
			for y in HEIGHT:
				image.set_pixel(x, y, colors[i])


static func _draw_cross_flag(image: Image, pattern: Dictionary) -> void:
	var base: Color = pattern.get("base", Color.WHITE)
	var cross: Color = pattern.get("cross", Color.RED)
	var thickness := int(pattern.get("thickness", 6))
	image.fill(base)

	var center_x := WIDTH / 2
	var center_y := HEIGHT / 2
	for x in WIDTH:
		for y in HEIGHT:
			if abs(x - center_x) < thickness or abs(y - center_y) < thickness:
				image.set_pixel(x, y, cross)


static func _c(hex: String) -> Color:
	return Color.html(hex)


static var _PATTERNS: Dictionary = {
	"AD": {"type": "v", "colors": [_c("#0018A8"), _c("#FEDF00"), _c("#D0103C")]},
	"AL": {"type": "solid", "color": _c("#E41E20")},
	"AM": {"type": "h", "colors": [_c("#D90012"), _c("#0033A0"), _c("#F2A800")]},
	"AT": {"type": "h", "colors": [_c("#ED2939"), _c("#FFFFFF"), _c("#ED2939")]},
	"AZ": {"type": "h", "colors": [_c("#00AF66"), _c("#E70013"), _c("#0098C3")]},
	"BA": {"type": "v", "colors": [_c("#002395"), _c("#FECB00")]},
	"BE": {"type": "v", "colors": [_c("#000000"), _c("#FAE042"), _c("#ED2939")]},
	"BG": {"type": "h", "colors": [_c("#FFFFFF"), _c("#00966E"), _c("#D62612")]},
	"BY": {"type": "h", "colors": [_c("#CE1720"), _c("#007C30")]},
	"CH": {"type": "cross", "base": _c("#D52B1E"), "cross": _c("#FFFFFF"), "thickness": 5},
	"CY": {"type": "solid", "color": _c("#FFFFFF")},
	"CZ": {"type": "h", "colors": [_c("#FFFFFF"), _c("#D7141A")]},
	"DE": {"type": "h", "colors": [_c("#000000"), _c("#DD0000"), _c("#FFCE00")]},
	"DK": {"type": "cross", "base": _c("#C8102E"), "cross": _c("#FFFFFF"), "thickness": 4},
	"EE": {"type": "h", "colors": [_c("#0072CE"), _c("#000000"), _c("#0072CE")]},
	"ES": {"type": "h", "colors": [_c("#AA151B"), _c("#F1BF00"), _c("#AA151B")]},
	"FI": {"type": "cross", "base": _c("#FFFFFF"), "cross": _c("#003580"), "thickness": 4},
	"FR": {"type": "v", "colors": [_c("#0055A4"), _c("#FFFFFF"), _c("#EF4135")]},
	"GB": {"type": "cross", "base": _c("#012169"), "cross": _c("#FFFFFF"), "thickness": 6},
	"GE": {"type": "solid", "color": _c("#FFFFFF")},
	"GR": {"type": "h", "colors": [_c("#0D5EAF"), _c("#FFFFFF"), _c("#0D5EAF"), _c("#FFFFFF"), _c("#0D5EAF")]},
	"HR": {"type": "h", "colors": [_c("#FF0000"), _c("#FFFFFF"), _c("#171796")]},
	"HU": {"type": "h", "colors": [_c("#CE2939"), _c("#FFFFFF"), _c("#477050")]},
	"IE": {"type": "v", "colors": [_c("#169B62"), _c("#FFFFFF"), _c("#FF883E")]},
	"IS": {"type": "cross", "base": _c("#02529C"), "cross": _c("#FFFFFF"), "thickness": 4},
	"IT": {"type": "v", "colors": [_c("#009246"), _c("#FFFFFF"), _c("#CE2B37")]},
	"KZ": {"type": "solid", "color": _c("#00AFCA")},
	"LI": {"type": "h", "colors": [_c("#002780"), _c("#CE1126")]},
	"LT": {"type": "h", "colors": [_c("#FDB913"), _c("#006A44"), _c("#C1272D")]},
	"LU": {"type": "h", "colors": [_c("#ED2939"), _c("#FFFFFF"), _c("#00A1DE")]},
	"LV": {"type": "solid", "color": _c("#9E3039")},
	"MC": {"type": "h", "colors": [_c("#CE1126"), _c("#FFFFFF")]},
	"MD": {"type": "v", "colors": [_c("#0046AE"), _c("#FFD200"), _c("#CC092F")]},
	"ME": {"type": "solid", "color": _c("#C40308")},
	"MK": {"type": "solid", "color": _c("#D20000")},
	"MT": {"type": "v", "colors": [_c("#FFFFFF"), _c("#CF142B")]},
	"NL": {"type": "h", "colors": [_c("#AE1C28"), _c("#FFFFFF"), _c("#21468B")]},
	"NO": {"type": "cross", "base": _c("#BA0C2F"), "cross": _c("#FFFFFF"), "thickness": 4},
	"PL": {"type": "h", "colors": [_c("#FFFFFF"), _c("#DC143C")]},
	"PT": {"type": "v", "colors": [_c("#006600"), _c("#FF0000")]},
	"RO": {"type": "v", "colors": [_c("#002B7F"), _c("#FCD116"), _c("#CE1126")]},
	"RS": {"type": "h", "colors": [_c("#C6363C"), _c("#0C4076"), _c("#FFFFFF")]},
	"RU": {"type": "h", "colors": [_c("#FFFFFF"), _c("#0039A6"), _c("#D52B1E")]},
	"SE": {"type": "cross", "base": _c("#006AA7"), "cross": _c("#FECC00"), "thickness": 4},
	"SI": {"type": "h", "colors": [_c("#FFFFFF"), _c("#005DA4"), _c("#FF0000")]},
	"SK": {"type": "h", "colors": [_c("#FFFFFF"), _c("#0B4EA2"), _c("#EE1C25")]},
	"SM": {"type": "h", "colors": [_c("#FFFFFF"), _c("#5EB6E4")]},
	"TR": {"type": "solid", "color": _c("#E30A17")},
	"UA": {"type": "h", "colors": [_c("#005BBB"), _c("#FFD500")]},
	"VA": {"type": "v", "colors": [_c("#FFE000"), _c("#FFFFFF")]},
	"XK": {"type": "solid", "color": _c("#244AA5")},
}
