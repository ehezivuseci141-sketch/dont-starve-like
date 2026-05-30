# 你的 Claude — core/ 系统负责人

## 职责范围

只改 `core/` 和 `shared/`：

| 文件 | 功能 | 注意 |
|------|------|------|
| `core/player.gd` | 移动/攻击/动画/交互/放置 | 双模式逻辑（ACTION+STRATEGIC） |
| `core/survival.gd` | 饥饿/生命/夜晚伤害/火堆检测 | `_near_campfire()` 判断火堆附近 |
| `core/inventory.gd` | 15格背包 | slot 可为 `{item_id, amount, dur}` |
| `core/crafting.gd` | 合成配方 + 耐久注入 | 新武器需在 craft() 注入 `dur` 字段 |
| `core/save_system.gd` | 存档 | 预留，暂未启用 |

## 队友的模块（绝对不碰）

- ❌ `world/` — 地图、群系、昼夜、天气、世界管理
- ❌ `scenes/enemy.gd` — 蜘蛛 AI
- ❌ `scenes/enemy_spawner.gd`
- ❌ `scenes/camera_follow.gd` — 相机+缩放
- ❌ `scenes/ground_renderer.gd`

## 通信协议

**通过 `shared/signals.gd` 发信号，不直接调对方函数。**

你负责的信号：
- `player_moved`, `player_picked_up`, `player_dropped`, `player_ate`, `player_died`
- `hunger_changed`, `health_changed`, `sanity_changed`, `player_starving`, `player_insane`

你监听的信号：
- `day_elapsed`, `season_changed`（季节影响饥饿速度）
- `time_of_day_changed`（夜晚判断）
- `entity_attacked_player`（怪物伤害）
- `weather_changed`

## 新增功能规范

- 新物品 → `shared/item_data.gd` 的 `_register_all_items()`
- 新配方 → `core/crafting.gd` 的 `_register_all_recipes()`
- 新信号 → `shared/signals.gd`，加完通知队友
- 武器有耐久 → 合成时注入 `dur` 字段，player 攻击时减 1

## 当前技术栈

- Godot 4.6 GDScript
- CharacterBody2D 玩家
- Sprite2D + TextureRect（贴图）
- CanvasLayer（UI）
- 信号驱动的 MVC 架构
