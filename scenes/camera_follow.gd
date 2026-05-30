# 简单相机跟随脚本
extends Camera2D

@export var target_path: NodePath
var target: Node2D

func _ready():
	if target_path:
		target = get_node(target_path)
	else:
		# 自动查找 Player 节点
		var players = get_tree().root.find_children("Player", "", true, false)
		if players.size() > 0:
			target = players[0]

func _process(_delta):
	if target:
		global_position = target.global_position
