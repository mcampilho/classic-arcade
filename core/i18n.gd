class_name I18n
extends RefCounted
## Translations: the original English text is the key; i18n/strings.gd has Portuguese and Spanish.
## I18n.t("Play") returns the text in the chosen language (or the English one if there is none).
## Labels and Buttons also translate themselves when their text is exactly a key.

const LANGS := ["en", "pt", "es"]
const LANG_NAMES := ["English", "Português", "Español"]
const STRINGS := preload("res://i18n/strings.gd")

static var lang := "en"
static var _loaded := false


## The system language, if it is supported (otherwise English).
static func system_lang() -> String:
	var l := OS.get_locale_language()
	return l if l in LANGS else "en"


static func setup(p_lang: String) -> void:
	lang = p_lang if p_lang in LANGS else "en"
	if not _loaded:
		_loaded = true
		for i in range(1, LANGS.size()):
			var tr := Translation.new()
			tr.locale = LANGS[i]
			for k: String in STRINGS.T:
				var v: Array = STRINGS.T[k]
				if v.size() >= i and String(v[i - 1]) != "":
					tr.add_message(k, v[i - 1])
			TranslationServer.add_translation(tr)
	TranslationServer.set_locale(lang)


static func t(s: String) -> String:
	if lang == "en":
		return s
	return String(TranslationServer.translate(s))
