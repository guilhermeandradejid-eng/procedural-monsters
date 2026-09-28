class_name Pal
extends RefCounted
## Art-direction palette. Every colour in the game should come from here so the
## look stays coherent: warm parchment, iron-gall ink, gold leaf, sealing wax.

const PAPER := Color("efe2c4")
const PAPER_LIGHT := Color("f7eedb")
const PAPER_DARK := Color("d9c49a")
const PAPER_SHADOW := Color("b89a6a")
const INK := Color("1c1411")
const INK_SOFT := Color("3a2a22")
const INK_FADED := Color("6b5a4a")
const SEPIA := Color("6b4a2f")
const GOLD := Color("c9a15b")
const GOLD_BRIGHT := Color("f0c96a")
const WAX := Color("9e2b25")
const WAX_DARK := Color("6e1a17")
const WAX_LIGHT := Color("c9483c")
const EMBER := Color("ff8a2b")
const EMBER_HOT := Color("ffd06a")
const ABYSS := Color("120c0b")
const HEAL := Color("8fe07a")
const DANGER := Color("e8472e")
const TELEGRAPH := Color("ff5a36")

## Per-player identity colours (flame + tabard).
const PLAYER_FLAME: Array[Color] = [Color("ff8a2b"), Color("4cc3e8"), Color("c08cff"), Color("a6dc4e")]
const PLAYER_CLOTH: Array[Color] = [Color("b8452a"), Color("2d6f91"), Color("6a3fa0"), Color("5c7d2b")]
const PLAYER_NAMES: Array[String] = ["Brasa", "Maré", "Vigília", "Ramo"]


static func player_flame(i: int) -> Color:
	return PLAYER_FLAME[clampi(i, 0, 3)]


static func player_cloth(i: int) -> Color:
	return PLAYER_CLOTH[clampi(i, 0, 3)]


static func with_alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)
