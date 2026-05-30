# 伙伴的 Claude — world/ 系统负责人

## 职责范围

你只负责 `world/` 目录下的文件：
- `world/world_manager.gd` — 世界管理器（统筹地图+实体）
- `world/map_generator.gd` — 地图生成（柏林噪声）
- `world/biome.gd` — 生物群落配置
- `world/day_night.gd` — 昼夜循环
- `world/weather.gd` — 天气系统
- `world/entities/` — 生物 AI（后续阶段）

## 绝对不要碰

- ❌ `core/` 目录下的任何文件
- ❌ 直接修改玩家的生存数值、背包、合成
- ❌ 存档系统

## 通信方式

你通过 `shared/signals.gd` 中的信号与 core 系统通信：

### 你监听的信号（来自 core 系统）
- `player_moved` — 知道玩家在哪，用来在周围刷怪
- `player_picked_up` — 物品被捡走了
- `player_died` — 玩家死了，也许要清理世界状态
- `item_dropped_in_world` — 玩家丢弃物品到地面

### 你发出的信号（core 系统会监听）
- `time_of_day_changed` — 白天/黄昏/夜晚切换
- `day_elapsed` — 新的一天
- `season_changed` — 季节切换（影响 core 的饥饿速度）
- `weather_changed` — 天气变化
- `entity_attacked_player` — 怪物攻击玩家（core 扣血）
- `entity_spawned` / `entity_died` — 实体生灭
- `item_dropped_in_world` — 世界生成的掉落物
- `item_collected_from_world` — 物品被捡起

## 编码规范

1. **地图相关都用 world_to_grid/grid_to_world 转换坐标**
2. **所有生物群系判断走 biome_grid**，不要硬编码
3. **新增生物群落**：在 `world/biome.gd` 和 `shared/enums.gd` 里加，通知对方
4. **季节逻辑**：季节长度在 day_night.gd 的 `SEASON_LENGTH` 常量
5. **天气影响**：需要在 `world/weather.gd` 中处理对玩家的影响（通过信号）

## 测试你的代码

修改代码后，确认：
- 地图在生成时没有卡死 ✓
- 昼夜在切换（8 分钟一天）✓
- 季节在流转（20 天一个季节）✓
- 满地有浆果、胡萝卜等可采集物 ✓
- 夜晚有蜘蛛出没（后续阶段）✓
- 下雨时玩家会变湿 ✓

## 当前阶段：白盒原型

- 用 FastNoiseLite 生成 256×256 地形
- 5 种生物群系（森林/草原/岩石地/沼泽/稀树草原）
- 昼夜每 160 秒切换一次
- 天气随机切换
- **目标是验证世界系统骨架正确，实体 AI 后续再写**
