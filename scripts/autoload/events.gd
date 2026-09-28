extends Node
## Gameplay event bus. Relics, the HUD, stats and audio listen here so
## actors never need to know who cares about what they do.

signal enemy_killed(enemy: Node3D, hit: Hit)
signal enemy_spawned(enemy: Node3D)
signal player_damaged(player: Node3D, hit: Hit)
signal player_downed(player: Node3D)
signal player_revived(player: Node3D)
signal spell_cast(player: Node3D, program: SpellProgram, page: int)
signal melee_hit(player: Node3D, enemy: Node3D, hit: Hit)
signal perfect_dodge(player: Node3D)
signal dashed(player: Node3D)
signal room_cleared
signal room_started
signal pickup(player: Node3D, kind: String, amount: int)
signal boss_phase(phase: int)
signal toast(text: String, color: Color)
