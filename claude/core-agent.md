# 你的 Claude — core/ 系统负责人

## 职责范围

你只负责 `core/` 目录下的文件：
- `core/player.gd` — 玩家控制器（移动、交互）
- `core/survival.gd` — 生存数值（饥饿/生命/精神）
- `core/inventory.gd` — 背包系统
- `core/crafting.gd` — 合成配方
- `core/save_system.gd` — 存档/读档

## 绝对不要碰

- ❌ `world/` 目录下的任何文件
- ❌ 直接操作世界中的实体、怪物、天气
- ❌ 地图生成相关代码

## 通信方式

你通过 `shared/signals.gd` 中的信号与 world 系统通信：

### 你发出的信号（world 系统会监听）
- `player_moved` — 每次玩家移动时发出
- `player_picked_up` — 捡起物品时
- `player_dropped` — 丢弃物品时
- `player_ate` — 吃东西时
- `player_died` — 玩家死亡时
- `hunger_changed`, `health_changed`, `sanity_changed` — 数值变化时

### 你监听的信号（来自 world 系统）
- `day_elapsed` — 新的一天开始
- `season_changed` — 季节变化（影响饥饿速度）
- `entity_attacked_player` — 怪物攻击玩家
- `weather_changed` — 天气变化

## 编码规范

1. **所有数值修改都通过 SurvivalManager**，不要在其他地方直接改 hunger/health/sanity
2. **物品查询都用 ItemDB**，不要硬编码物品属性
3. **新增物品**：在 `shared/item_data.gd` 里加，然后通知伙伴
4. **新增合成配方**：在 `core/crafting.gd` 的 `_register_all_recipes()` 里加
5. **存档兼容**：修改数据结构时，同时更新 `serialize()` 和 `deserialize()`

## 测试你的代码

修改代码后，在 Godot 中按 F5 运行，确认：
- 玩家能用 WASD 移动 ✓
- 饥饿值在往下掉 ✓
- 按 E 能捡起附近物品 ✓
- 按 1-0 能切换物品 ✓
- 按 F 能吃选中的食物 ✓
- 按 Q 能丢弃物品 ✓
- 按 Tab 能打开背包（目前打印到控制台）✓
- 按 C 能打开合成界面（目前打印到控制台）✓

## 当前阶段：白盒原型

- 玩家是绿色圆形
- 物品是彩色方块
- 数据在控制台打印
- 没有真正的 UI 界面
- **目标是验证系统逻辑正确，不是好看**
