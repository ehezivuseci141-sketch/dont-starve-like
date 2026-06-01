extends Node
class_name CombatSystem

static func apply_damage(target: Node, amount: float, source: Node = null) -> bool:
	if target == null:
		return false
	if target.has_method("take_damage"):
		target.take_damage(amount)
		return true
	if target == SurvivalManager:
		SurvivalManager.take_damage(amount)
		return true
	return false

static func facing_dot(attacker_pos: Vector2, target_pos: Vector2, attack_dir: Vector2) -> float:
	var to_target = target_pos - attacker_pos
	if to_target.length() <= 0.01 or attack_dir.length() <= 0.01:
		return 1.0
	return attack_dir.normalized().dot(to_target.normalized())
