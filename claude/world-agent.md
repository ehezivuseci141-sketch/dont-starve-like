# 伙伴的 Claude — world/ 系统负责人

## 职责范围

只改 `world/` 和 `scenes/` 中的世界相关文件：

| 文件 | 功能 | 注意 |
|------|------|------|
| `world/world_manager.gd` | 世界管理 + 实体刷新 | 自动生成地图在 `_ready()` |
| `world/map_generator.gd` | 柏林噪声地图 | FastNoiseLite，5种群系 |
| `world/biome.gd` | 群系配置 | 颜色/可采集物/生物列表 |
| `world/day_night.gd` | 昼夜循环 | 120s/天，5天/季（测试值） |
| `world/weather.gd` | 天气系统 | 晴/雨/雪/雾/暴风雨 |
| `scenes/enemy.gd` | 蜘蛛 AI | 白天游荡/夜晚追击/攻击 |
| `scenes/enemy_spawner.gd` | 夜晚刷怪 | 信号驱动 |
| `scenes/ground_renderer.gd` | 地面渲染 | 根据 WorldManager 的 biome_grid 着色 |
| `scenes/night_overlay.gd` | 夜晚暗幕 | CanvasLayer 滤镜 |
| `scenes/world_spawner.gd` | 资源散布 | `simple_pickable.gd` |
| `scenes/campfire.gd` | 火堆实体 | 燃烧/燃料/光亮范围 |

## 队友的模块（绝对不碰）

- ❌ `core/` — 玩家、生存值、背包、合成、存档
- ❌ `scenes/player.tscn`, `scenes/hud.gd`, `scenes/hotbar.gd`, `scenes/inventory_panel.gd`
- ❌ `scenes/camera_follow.gd`

## 通信协议

**通过 `shared/signals.gd` 发信号，不直接调对方函数。**

你负责的信号：
- `day_elapsed`, `time_of_day_changed`, `season_changed`, `weather_changed`
- `entity_spawned`, `entity_died`, `entity_attacked_player`
- `item_dropped_in_world`, `item_collected_from_world`

你监听的信号：
- `player_moved`（知道玩家位置，周围刷怪）
- `player_died`（清理世界状态）

## 新增功能规范

- 新生物群系 → `shared/enums.gd` 的 `BiomeType` + `world/biome.gd` 配置
- 新天气 → `shared/enums.gd` 的 `Weather` + `world/weather.gd`
- 新敌人 → `scenes/` 新建脚本，在 `enemy_spawner.gd` 或 `world_manager.gd` 注册
- 新信号 → `shared/signals.gd`，加完通知队友

## 当前时间参数

```
DAY_LENGTH = 120 秒（2分钟/天）
DAY_SEGMENT = 40 秒（白天/黄昏/夜晚各40秒）
SEASON_LENGTH = 5 天（10分钟/季）
```
正式发布时改回 480/160/20。

## 敌人 AI 状态机

```
0=WANDER  白天慢速游荡，夜晚在玩家附近游荡
1=CHASE   夜晚靠近玩家时追击（距离<250）
2=ATTACK  近身攻击（距离<40），cd=1.5s，伤害=8
```
有牵引绳机制（不会离开玩家>500距离）。
