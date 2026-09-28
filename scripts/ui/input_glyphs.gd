class_name InputGlyphs
extends RefCounted
## Short button names per device for prompts and the controls page.

const KBM := {
	"attack": "LMB", "spell_0": "RMB", "spell_1": "Q", "spell_2": "E", "dash": "Space",
	"interact": "F", "grimoire": "Tab", "pause": "Esc",
	"ui_accept": "Enter", "ui_back": "Esc", "ui_prev": "Q", "ui_next": "E", "ui_alt": "X",
}
const KB2 := {
	"attack": "/", "spell_0": ".", "spell_1": ",", "spell_2": "M", "dash": "RShift",
	"interact": "Enter", "grimoire": ";", "pause": "Esc",
	"ui_accept": "/", "ui_back": "RShift", "ui_prev": ",", "ui_next": ".", "ui_alt": "M",
}
const PAD := {
	"attack": "X", "spell_0": "Y", "spell_1": "B", "spell_2": "RB", "dash": "A",
	"interact": "LB", "grimoire": "Select", "pause": "Start",
	"ui_accept": "A", "ui_back": "B", "ui_prev": "LB", "ui_next": "RB", "ui_alt": "X",
}


static func table(input: PlayerInput) -> Dictionary:
	if input == null:
		return KBM
	match input.kind:
		PlayerInput.Kind.KBM:
			return KBM
		PlayerInput.Kind.KB_ARROWS:
			return KB2
	return PAD


static func label(input: PlayerInput, action: String) -> String:
	return "[%s]" % table(input).get(action, "?")


static func raw(input: PlayerInput, action: String) -> String:
	return table(input).get(action, "?")
