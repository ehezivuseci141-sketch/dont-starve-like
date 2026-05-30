# 🌲 DontStarveLike

**类饥荒生存游戏** — 用 Godot 4 + 两个 Claude Code 协作开发

---

## 📂 项目结构

```
dont-starve-like/
├── core/                    ← 👤 你的 Claude 负责
│   ├── player.gd            玩家控制器
│   ├── survival.gd          饥饿/生命/精神数值
│   ├── inventory.gd         背包系统
│   ├── crafting.gd          合成配方
│   └── save_system.gd       存档/读档
│
├── world/                   ← 👥 伙伴的 Claude 负责
│   ├── world_manager.gd     世界管理器
│   ├── map_generator.gd     地图生成（柏林噪声）
│   ├── biome.gd             生物群落配置
│   ├── day_night.gd         昼夜循环
│   ├── weather.gd           天气系统
│   └── entities/            生物 AI（后续阶段）
│
├── shared/                  ← 🔗 协议层（一起维护）
│   ├── signals.gd           全局信号总线
│   ├── enums.gd             枚举定义
│   └── item_data.gd         物品数据库
│
├── scenes/                  ← 🎬 场景文件
│   ├── main_scene.tscn      主场景
│   ├── player.tscn           玩家场景
│   ├── pickable_item.tscn   可采集物品场景
│   ├── hud.gd               HUD 控制器
│   └── pickable_item.gd     物品脚本
│
├── assets/                  ← 🎨 资源
│   ├── sprites/             精灵图（目前是占位色块）
│   ├── sounds/              音效（待添加）
│   └── fonts/               字体
│
├── claude/                  ← 🤖 Claude 协作规则
│   ├── core-agent.md        你的 Claude 规则
│   └── world-agent.md       伙伴的 Claude 规则
│
└── project.godot            ← ⚙️ Godot 项目配置
```

---

## 🚀 快速开始

### 1. 安装 Godot 4

从 https://godotengine.org 下载 **Godot 4.X**（60MB，免费）

### 2. 打开项目

```
打开 Godot 4 → 导入 → 选择 dont-starve-like/project.godot
```

### 3. 运行

按 **F5**，你应该看到：
- 一个绿色圆形（玩家）
- 用 WASD 可以移动
- 左上角 3 条状态栏（饥饿/生命/精神）
- 地上散落的彩色方块（可采集物）
- 走到物品旁边按 E 捡起来
- 按 F 吃食物
- 饥饿条一直在往下掉

### 4. 操作说明

| 按键 | 功能 |
|------|------|
| WASD / 方向键 | 移动 |
| E | 交互（采集/砍树/挖矿） |
| F | 吃当前选中的物品 |
| Q | 丢弃当前物品 |
| Tab | 打开背包（控制台输出） |
| C | 打开合成（控制台输出） |
| 1-0 | 切换物品槽位 |

---

## 🤝 两个人的协作流程

### day 1：一起跑通
1. 都装好 Godot 4
2. 都克隆 `git clone ...`
3. 确认 F5 能跑起来
4. 你打开 `core/player.gd`，改移动速度 200→300，跑一下确认生效
5. 伙伴打开 `world/day_night.gd`，改 `DAY_LENGTH` 480→60（1分钟一天），确认生效

### 日常开发
```
你                                      伙伴
│                                        │
├─ 和 Claude 讨论要改什么                  ├─ 和他的 Claude 讨论
├─ Claude 写 core/ 代码                    ├─ Claude 写 world/ 代码
├─ 只改 core/ 和 shared/                   ├─ 只改 world/ 和 shared/
├─ git commit -m "core: xxx"              ├─ git commit -m "world: xxx"
├─ git push                               ├─ git pull && git push
│                                        │
├─────── 遇到冲突就一起看 shared/ ──────────┤
│                                        │
└─────── 每次改动后 F5 跑一下 ──────────────┘
```

### 改了 shared/ 怎么办
- `shared/signals.gd` — 加了新信号，在群里说一声
- `shared/enums.gd` — 加了新枚举，通知对方更新对应代码
- `shared/item_data.gd` — 加了新物品，双方做一次 git pull

---

## 🗺️ 开发路线图

### ✅ 阶段一：白盒原型（当前）
- [x] 项目骨架搭完
- [x] Godot 项目配置
- [x] 信号总线 + 枚举 + 物品数据
- [x] 核心系统（玩家/生存/背包/合成/存档）
- [x] 世界系统（地图生成/群落/昼夜/天气）
- [ ] 能在 Godot 里跑起来，看到效果 ← **下一步**
- [ ] 地上自动刷可采集物品
- [ ] 合成功能验证

### 🟡 阶段二：一个小世界（2-3 个月）
- [ ] 地图可视化（不同群落不同颜色）
- [ ] 火堆系统（放置/点燃/取暖）
- [ ] 基础砍树挖矿
- [ ] 简单的 UI（背包网格、合成面板）
- [ ] 食物腐烂机制
- [ ] 基础存档读档验证

### 🟠 阶段三：有威胁了（2-3 个月）
- [ ] 蜘蛛 AI（晚上出没）
- [ ] 战斗系统
- [ ] 猎犬波次攻击
- [ ] 理智值低→幻觉效果
- [ ] 雨天灭火机制

### 🔴 阶段四：像个游戏了（3-4 个月）
- [ ] 四季系统完整实现
- [ ] 多种生物（猪人/兔人/高脚鸟）
- [ ] 地下洞穴
- [ ] 烹饪系统
- [ ] 真正的美术资源

### ⚫ 阶段五：联机（6 个月+）
- [ ] Godot Multiplayer 架构
- [ ] 主机-客户端模式
- [ ] 同步所有信号
- [ ] 断线重连

---

## 📝 给两个 Claude 的 Prompt 示例

### 你的 Claude（core 负责人）
```
"我现在要改玩家的饥饿系统。
相关文件：core/survival.gd, shared/enums.gd, shared/signals.gd
要求：冬天饥饿速度提高 25%，已在 enums.gd 里加了 WINTER。
请只改 core/survival.gd，通过监听 season_changed 信号实现。"
```

### 伙伴的 Claude（world 负责人）
```
"我要加沼泽生物群系的触手怪。
相关文件：world/biome.gd, world/entities/tentacle.gd, shared/signals.gd
触手藏在沼泽地面下，玩家靠近时冒出来攻击。
用 entity_attacked_player 信号通知 core 扣血。"
```

---

## ⚠️ 重要提醒

1. **不要一开始就做美术** — 色块能跑通再换图
2. **每次改完立刻 F5 测试** — 别攒一堆 bug 再修
3. **Git 提交勤快** — 每完成一个小功能就 commit
4. **别碰对方的目录** — 你的 Claude 只改 core/，他的只改 world/
5. **shared/ 是公共协议** — 改了要通知对方
6. **不要追求完美** — 先做能跑的，再做好看的

---

> 🎮 两年很长。但如果今天开始，两年后你就是"做过游戏的人"。
> 今天不做，两年后还是"想做游戏的人"。
