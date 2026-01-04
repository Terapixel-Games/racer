extends Resource

const CHARSET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const LENGTH := 6

static func generate() -> String:
	var code := ""
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in LENGTH:
		code += CHARSET[rng.randi_range(0, CHARSET.length() - 1)]
	return code

static func normalize(code:String) -> String:
	return code.strip_edges().to_upper()
