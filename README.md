# 🌲 DontStarveLike

**类饥荒生存游戏** — Godot 4.6 + 双人双 Claude 协作开发

---

## 🎮 当前功能

### 核心玩法
- WASD 移动（ACTION 模式）/ 鼠标点击移动（STRATEGIC 模式）
- 空格或鼠标左键攻击（朝向限定 ~50° 锥形范围）
- E 键采集资源，F 键吃食物，Q 键丢弃，B 键放置建筑
- 饥饿值 + 生命值系统，夜晚无火堆持续扣血

### 双模式系统
| | ACTION 模式 | STRATEGIC 模式 |
|------|-----------|--------------|
| 切换 | 滚轮上放大 | 滚轮下缩小 |
| 移动 | WASD | 鼠标左键点地板 |
| 攻击 | 空格 / 左键 | 空格 |
| 视角 | 贴身 | 全局俯瞰 |

### 物品 & 合成
- 9 种资源：浆果、胡萝卜、树枝、草、原木、石头、燧石、金块、生肉
- 5 个配方：矛、斧头、镐子、火堆、熟肉
- Tab 打开合成面板，点击配方制作
- 武器耐久：矛/斧/镐每次攻击 -1，归零损坏

### 世界
- 256×256 柏林噪声地图，5 种群系
- 昼夜循环（2 分钟/天），5 天/季
- 天气系统：晴/雨/雪/雾/暴风雨
- 蜘蛛敌人：夜晚主动攻击，白天游荡
- 火堆：B 键放置，燃烧 60 秒，夜晚站在旁边免疫伤害

### UI
- 左上：饥饿/生命条 + 天数/季节/天气
- 底部：5 格快捷栏（贴图 + 数量 + 耐久 + 金框选中）
- Tab：背包+合成面板（左右分栏，贴图图标，点击拖拽）
- 右侧面板：背包 15 格 → 点击 Craft 按钮切换合成

---

## 📂 项目结构

```
dont-starve-like/
├── core/                    ← 👤 你负责
│   ├── player.gd            玩家：移动/攻击/动画/交互/放置
│   ├── survival.gd          生存值 + 夜晚伤害 + 火堆检测
│   ├── inventory.gd         15格背包（支持耐久度字段）
│   ├── crafting.gd          合成系统（含配方 + 耐久注入）
│   └── save_system.gd       存档（开发中）
│
├── world/                   ← 👥 伙伴负责
│   ├── world_manager.gd     世界管理器 + 实体刷新
│   ├── map_generator.gd     柏林噪声地图生成 (FastNoiseLite)
│   ├── biome.gd             5种群系配置
│   ├── day_night.gd         昼夜循环 + 季节
│   └── weather.gd           天气系统
│
├── shared/                  ← 🔗 公共协议
│   ├── signals.gd           全局信号总线
│   ├── enums.gd             枚举定义
│   └── item_data.gd         物品数据库（唯一数据源）
│
├── scenes/                  ← 🎬 场景
│   ├── main_scene.tscn      主场景
│   ├── player.tscn           玩家场景
│   ├── campfire.gd          火堆实体
│   ├── enemy.gd             蜘蛛 AI
│   ├── enemy_spawner.gd     敌人刷新
│   ├── world_spawner.gd     资源散布
│   ├── ground_renderer.gd   地面群系渲染
│   ├── simple_pickable.gd   可采集物品
│   ├── camera_follow.gd     相机跟随 + 缩放双模式
│   ├── inventory_panel.gd   背包/合成面板（统一侧栏）
│   ├── hotbar.gd            底部快捷栏
│   ├── hud.gd               左上 HUD（状态条+时间天气）
│   └── night_overlay.gd     夜晚暗幕
│
├── assets/sprites/          ← 🎨 贴图
│   ├── player.png           角色
│   ├── berries/carrot/twigs/cut_grass/log/rocks/flint/... .png
│   ├── spear/axe/pickaxe.png
│   └── spider.png
│
├── claude/                  ← 🤖 协作规则
│   ├── core-agent.md        你的 Claude 规范
│   └── world-agent.md       伙伴的 Claude 规范
│
└── project.godot            ← ⚙️ 项目配置
```

---

## 🚀 快速开始

1. 安装 **Godot 4.6**（标准版，不要 .NET）
2. `git clone` 本项目
3. Godot 打开 `project.godot` → F5 → F7 运行

---

## 🤝 协作流程

```
你只改 core/ + shared/       伙伴只改 world/ + shared/
各自 git push / git pull
通过 shared/signals.gd 通信，不直接调用对方模块
改了 shared/ 通知对方
```

---

## ⌨️ 完整键位

| 按键 | 功能 |
|------|------|
| WASD | 移动（ACTION 模式） |
| 鼠标左键 | 点地板走（STRATEGIC）/ 攻击（ACTION） |
| 空格 | 攻击 |
| 滚轮 | 缩放 / 切换模式 |
| E | 采集 |
| F | 吃食物 |
| Q | 丢弃 |
| B | 放置火堆 |
| Tab | 背包/合成面板 |
| 1-5 | 选快捷栏 |

---

## 📋 待开发

- [ ] 角色多帧动画（框架已就绪，等贴图）
- [ ] 小队系统（R 键招募）
- [ ] 建造系统（墙壁/箱子）
- [ ] 更多敌人（狼/猎犬波）
- [ ] 烹饪系统（火堆旁烹饪）
- [ ] 地下洞穴
- [ ] 联机模式
