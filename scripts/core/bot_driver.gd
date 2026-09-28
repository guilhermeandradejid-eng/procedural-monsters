class_name BotDriver
extends Node
## Automated player for smoke tests and co-op demos: drives knights through
## their own PlayerInput (so it exercises the real input path). Knight I is
## only botted with --bot; extra test knights are always bots.

var all_players := false
var _t := 0.0
var _state := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(delta: float) -> void:
	_t += delta
	for prof in Game.profiles:
		if prof.index == 0 and not all_players:
			continue
		var p := prof.actor as Player
		if p == null or not is_instance_valid(p) or p.downed:
			continue
		_drive(prof, p, delta)


func _press(input: PlayerInput, action: String) -> void:
	input.set_action(action, false)
	input.set_action(action, true)
	input.set_action(action, false)


func _drive(prof: PlayerProfile, p: Player, delta: float) -> void:
	var input := prof.input
	input.virtual = true
	var st: Dictionary = _state.get(prof.index, {"cd": 0.0, "wander": Vector2.ZERO, "wt": 0.0})
	st.cd -= delta
	st.wt -= delta
	var level := Level.current
	var target := Combat.nearest_enemy(p.global_position, 40.0)
	var move := Vector2.ZERO
	if target and not (target is TrainingDummy):
		var to := Combat.flat(target.global_position - p.global_position)
		var d := to.length()
		var dir := Vector2(to.x, to.z).normalized()
		# Keep a comfortable distance, strafe around.
		var side := Vector2(-dir.y, dir.x) * (1.0 if int(_t / 3.0 + prof.index) % 2 == 0 else -1.0)
		if d > 7.0:
			move = dir
		elif d < 3.0:
			move = -dir * 0.8 + side * 0.6
		else:
			move = side * 0.8 + dir * 0.2
		input.stick_aim = dir
		if st.cd <= 0.0:
			st.cd = randf_range(0.18, 0.4)
			var roll := randf()
			if roll < 0.45 and d < 3.2:
				_press(input, "attack")
			elif roll < 0.85:
				_press(input, "spell_%d" % (randi() % 3))
			else:
				_press(input, "dash")
	else:
		# Nothing to fight: head for an open door or a reward.
		var goal := Vector3.ZERO
		var found := false
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.can_interact(p) and not (n is Station) and not (n is ShopStand):
				goal = n.global_position
				found = true
				break
		if found:
			var to2 := Combat.flat(goal - p.global_position)
			if to2.length() > 1.6:
				move = Vector2(to2.x, to2.z).normalized()
			elif st.cd <= 0.0:
				st.cd = 0.8
				_press(input, "interact")
		else:
			if st.wt <= 0.0:
				st.wt = 1.5
				st.wander = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			move = st.wander * 0.5
	input.move = move.limit_length(1.0)
	_state[prof.index] = st
	# Auto-accept choices (first card) so reward panels never block the bot.
	if Game.main and Game.main.ui.has_panel(prof):
		if st.cd <= 0.0:
			st.cd = 0.5
			_press(input, "ui_accept")
			if randf() < 0.3:
				_press(input, "ui_back")
