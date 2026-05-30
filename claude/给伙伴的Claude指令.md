# 给伙伴的 Claude —— 项目启动指令

你的主人和他的朋友 cxt 正在合作开发一款 **类饥荒生存游戏**，用 Godot 4.6 引擎 + GDScript。

你的主人负责 `world/` 目录，cxt 负责 `core/` 目录。你们通过 `shared/signals.gd` 通信。

---

## 一、环境准备

### 1. 安装 Godot 4.6
从 https://godotengine.org 下载 **Godot 4.6 标准版**（不要 .NET 版本，60MB）。

### 2. 配置 Git 代理（重要！人在国内必须配）

先打开你的 Clash Verge 主界面，找到 **端口** 那一栏的数字（通常是 7890、7897 等）。然后把下面命令里的 `你的端口` 换成那个数字：

```bash
git config --global http.proxy http://127.0.0.1:你的端口
git config --global https.proxy http://127.0.0.1:你的端口
```

验证是否生效：
```bash
git ls-remote https://github.com/ehezivuseci141-sketch/dont-starve-like.git
```
如果没报错就说明代理配置成功。

### 3. 克隆仓库
```bash
git clone https://github.com/ehezivuseci141-sketch/dont-starve-like.git
```

### 4. 打开项目
Godot → 导入 → 选择 `dont-starve-like/project.godot` → F5 运行 → F7 启动游戏窗口

---

## 二、你的职责

### 你只负责这些文件
| 文件 | 是什么 | 
|------|--------|
| `world/world_manager.gd` | 世界管理器，统筹地图生成和实体刷新 |
| `world/map_generator.gd` | 柏林噪声地图，5 种群系，256×256 |
| `world/biome.gd` | 群系配置（颜色、资源、生物） |
| `world/day_night.gd` | 昼夜循环，目前 2 分钟/天（测试值） |
| `world/weather.gd` | 天气系统（晴/雨/雪/雾/暴风雨） |
| `scenes/enemy.gd` | 蜘蛛 AI：白天游荡，夜晚追击+攻击 |
| `scenes/enemy_spawner.gd` | 夜晚刷怪，白天不杀 |
| `scenes/ground_renderer.gd` | 地面群系颜色渲染 |
| `scenes/night_overlay.gd` | 夜晚暗幕滤镜 |
| `scenes/world_spawner.gd` | 资源散布（浆果/树枝/石头等） |
| `scenes/campfire.gd` | 火堆实体（燃烧、燃料、光照范围） |

### 你绝对不改的
- `core/` 目录下所有文件
- `scenes/player.tscn`, `scenes/hud.gd`, `scenes/hotbar.gd`, `scenes/inventory_panel.gd`
- `scenes/camera_follow.gd`

（这些是 cxt 的地盘）

---

## 三、怎么和 cxt 的代码通信

你们通过 `shared/signals.gd` 互相发信号，**绝不直接调用对方模块的函数**。

### 你发出的信号（core 会监听）
```gdscript
Signals.time_of_day_changed.emit(new_time)   # 白天/黄昏/夜晚切换
Signals.day_elapsed.emit(day_count)           # 新的一天
Signals.season_changed.emit(new_season)        # 季节切换
Signals.weather_changed.emit(new_weather)      # 天气变化
Signals.entity_attacked_player.emit(entity_id, damage)  # 怪物打玩家
Signals.entity_spawned.emit(id, type, pos)     # 实体生成
Signals.entity_died.emit(id, type, pos, loot) # 实体死亡
Signals.item_dropped_in_world.emit(id, amount, pos)  # 世界掉落物品
```

### 你监听的信号（core 会发出）
```gdscript
Signals.player_moved    # 玩家位置，用来到周围刷怪/刷新资源
Signals.player_died     # 玩家死了，清世界状态
```

---

## 四、Git 协作流程

```
每次开始工作前：
  git pull

每次改完代码后：
  git add world/ scenes/enemy.gd ...  （只加你改的文件）
  git commit -m "world: 写清楚改了啥"
  git push
```

### 共享文件改完要通知
如果你改了 `shared/enums.gd`（加新枚举）、`shared/signals.gd`（加新信号）、`shared/item_data.gd`（加新物品），**在微信群里告诉 cxt**，让他也 `git pull`。

---

## 五、现在可以做什么

### 推荐先做的
1. **加新敌人**：比如狼（速度快、白天也攻击）、蜜蜂（中立、被打后还击）
2. **资源重生优化**：`world_spawner.gd` 里加定时重生逻辑
3. **蜘蛛巢穴**：可破坏的结构，定期刷蜘蛛
4. **天气视觉效果**：下雨时地面变暗、下雪时地面变白
5. **更多群系内容**：每个群系加专属生物和资源

### 技术要点
- 敌人模板参考 `scenes/enemy.gd`（CharacterBody2D + 状态机）
- 世界实体放在 `Game` 节点下（`get_parent().add_child()`）
- 贴图放在 `assets/sprites/`，游戏会自动加载同名 PNG
- Godot 4.6 的 `match` 语句默认分支 `_:` 可能报错，用 if-else 代替

---

## 六、运行测试

每次改完代码，在 Godot 里按 F5 运行：
- 能看到绿色地面和玩家小人 → 地图系统正常
- 滚轮缩放 → 相机正常
- 等 40 秒天黑 → 昼夜正常
- 天黑后有蜘蛛 → 敌人系统正常

---

## 七、当前项目状态（2026-05-30）

✅ 地图生成（柏林噪声 256×256）
✅ 5 种群系（草原/森林/岩石/沼泽/稀树草原）
✅ 昼夜循环（2分钟/天，5天/季）
✅ 天气系统
✅ 蜘蛛 AI（状态机+牵引绳）
✅ 相机缩放双模式（ACTION/STRATEGIC）
✅ 玩家移动/攻击/交互
✅ 背包+合成+拖拽
✅ 武器耐久
✅ 火堆放置+夜晚保护
✅ 地面群系渲染
✅ 夜晚暗幕

🛠️ 开发中：角色多帧动画、更多敌人、建造系统
