package wirepod_ttr

import (
	sr "github.com/kercre123/chipper/pkg/wirepod/speechrequest"
)

const STR_WEATHER_IN = "str_weather_in"
const STR_WEATHER_FORECAST = "str_weather_forecast"
const STR_WEATHER_TOMORROW = "str_weather_tomorrow"
const STR_WEATHER_THE_DAY_AFTER_TOMORROW = "str_weather_the_day_after_tomorrow"
const STR_WEATHER_TONIGHT = "str_weather_tonight"
const STR_WEATHER_THIS_AFTERNOON = "str_weather_this_afternoon"
const STR_EYE_COLOR_PURPLE = "str_eye_color_purple"
const STR_EYE_COLOR_BLUE = "str_eye_color_blue"
const STR_EYE_COLOR_SAPPHIRE = "str_eye_color_sapphire"
const STR_EYE_COLOR_YELLOW = "str_eye_color_yellow"
const STR_EYE_COLOR_TEAL = "str_eye_color_teal"
const STR_EYE_COLOR_TEAL2 = "str_eye_color_teal2"
const STR_EYE_COLOR_GREEN = "str_eye_color_green"
const STR_EYE_COLOR_ORANGE = "str_eye_color_orange"
const STR_ME = "str_me"
const STR_SELF = "str_self"
const STR_VOLUME_LOW = "str_volume_low"
const STR_VOLUME_QUIET = "str_volume_quiet"
const STR_VOLUME_MEDIUM_LOW = "str_volume_medium_low"
const STR_VOLUME_MEDIUM = "str_volume_medium"
const STR_VOLUME_NORMAL = "str_volume_normal"
const STR_VOLUME_REGULAR = "str_volume_regular"
const STR_VOLUME_MEDIUM_HIGH = "str_volume_medium_high"
const STR_VOLUME_HIGH = "str_volume_high"
const STR_VOLUME_LOUD = "str_volume_loud"
const STR_VOLUME_MUTE = "str_volume_mute"
const STR_VOLUME_NOTHING = "str_volume_nothing"
const STR_VOLUME_SILENT = "str_volume_silent"
const STR_VOLUME_OFF = "str_volume_off"
const STR_VOLUME_ZERO = "str_volume_zero"
const STR_NAME_IS = "str_name_is"
const STR_NAME_IS2 = "str_name_is1"
const STR_NAME_IS3 = "str_name_is2"
const STR_FOR = "str_for"

// All text must be lowercase!

var texts = map[string][]string{
	//  key                 			en-US   it-IT   es-ES    fr-FR    de-DE    ko-KR
	STR_WEATHER_IN:                     {" in ", " a ", " en ", " en ", " in "},
	STR_WEATHER_FORECAST:               {"forecast", "previsioni", "pronóstico", "prévisions", "wettervorhersage", "예보"},
	STR_WEATHER_TOMORROW:               {"tomorrow", "domani", "mañana", "demain", "morgen", "내일"},
	STR_WEATHER_THE_DAY_AFTER_TOMORROW: {"day after tomorrow", "dopodomani", "el día después de mañana", "lendemain de demain", "am tag nach morgen", "모레"},
	STR_WEATHER_TONIGHT:                {"tonight", "stasera", "esta noche", "ce soir", "heute abend", "오늘 밤"},
	STR_WEATHER_THIS_AFTERNOON:         {"afternoon", "pomeriggio", "esta tarde", "après-midi", "heute nachmittag", "오후"},
	STR_EYE_COLOR_PURPLE:               {"purple", "lilla", "violeta", "violet", "violett", "보라"},
	STR_EYE_COLOR_BLUE:                 {"blue", "blu", "azul", "bleu", "blau", "파랑"},
	STR_EYE_COLOR_SAPPHIRE:             {"sapphire", "zaffiro", "zafiro", "saphir", "saphir", "사파이어"},
	STR_EYE_COLOR_YELLOW:               {"yellow", "giallo", "amarillo", "jaune", "gelb", "노랑"},
	STR_EYE_COLOR_TEAL:                 {"teal", "verde acqua", "verde azulado", "sarcelle", "blaugrün", "청록"},
	STR_EYE_COLOR_TEAL2:                {"tell", "acquamarina", "aguamarina", "acquamarina", "acquamarina", "남옥"},
	STR_EYE_COLOR_GREEN:                {"green", "verde", "verde", "vert", "grün", "초록"},
	STR_EYE_COLOR_ORANGE:               {"orange", "arancio", "naranja", "orange", "orange", "주황"},
	STR_ME:                             {"me", "me", "me", "moi", "mir", "나"},
	STR_SELF:                           {"self", "mi", "mía", "moi", "mein"},
	STR_VOLUME_LOW:                     {"low", "basso", "bajo", "bas", "niedrig", "낮게"},
	STR_VOLUME_QUIET:                   {"quiet", "poco rumoroso", "tranquilo", "silencieux", "ruhig", "조용"},
	STR_VOLUME_MEDIUM_LOW:              {"medium low", "medio basso", "medio-bajo", "moyen-doux", "mittelschwer"},
	STR_VOLUME_MEDIUM:                  {"medium", "medio", "medio", "moyen", "mittel"},
	STR_VOLUME_NORMAL:                  {"normal", "normale", "normal", "normal", "normal", "보통"},
	STR_VOLUME_REGULAR:                 {"regular", "regolare", "regular", "régulier", "regulär"},
	STR_VOLUME_MEDIUM_HIGH:             {"medium high", "medio alto", "medio-alto", "moyen-élevé", "mittelhoch", "조금 높게"},
	STR_VOLUME_HIGH:                    {"high", "alto", "alto", "élevé", "hoch", "높게"},
	STR_VOLUME_LOUD:                    {"loud", "rumoroso", "fuerte", "fort", "laut", "시끄럽게"},
	STR_VOLUME_MUTE:                    {"mute", "muto", "mudo", "", "stumm", "무음"},
	STR_VOLUME_NOTHING:                 {"nothing", "nessuno", "nada", "rien", "nichts"},
	STR_VOLUME_SILENT:                  {"silent", "silenzioso", "silencio", "silencieux", "still"},
	STR_VOLUME_OFF:                     {"off", "spento", "apagado", "éteindre", "aus", "꺼"},
	STR_VOLUME_ZERO:                    {"zero", "zero", "cero", "zéro", "null", "영"},
	STR_NAME_IS:                        {" is ", " è ", " es ", " est ", " ist ", "은 "},
	STR_NAME_IS2:                       {"'s", "sono ", "soy ", "suis ", "bin ", "의 "},
	STR_NAME_IS3:                       {"names", " chiamo ", " llamo ", "appelle ", "werde", "이름들"},
	STR_FOR:                            {" for ", " per ", " para ", " pour ", " für "},
}

func getText(key string) string {
	var data = texts[key]
	if data != nil {
		if sr.SttLanguage == "it-IT" {
			return data[1]
		} else if sr.SttLanguage == "es-ES" {
			return data[2]
		} else if sr.SttLanguage == "fr-FR" {
			return data[3]
		} else if sr.SttLanguage == "de-DE" {
			return data[4]
		} else if sr.SttLanguage == "ko-KR" {
			return data[5]
		}
	}
	return data[0]
}
