# 猫狗大战 Cat Dog Battle

《猫狗大战》是一个用 Godot 4 + GDScript 开发的萌宠 3v3 拆家竞技原型。

当前目标不是做完整商业版，而是先完成一个能玩的第一版垂直切片：玩家只控制 1 只宠物，和 2 个 AI 队友一起，在客厅地图里抢道具、护送罐头炸弹、拦截敌方宠物，先拆掉对方宠物窝就赢。

## 当前版本

- 引擎：Godot 4.6.x
- 脚本：GDScript
- 视角：2D 俯视角
- 首要平台：Web
- 当前玩法：单机 3v3，玩家 1 只宠物 + 我方 2 个 AI，对方 3 个 AI
- 当前地图：客厅拆窝战场
- 当前美术：SVG 原型资源，已具备猫狗角色、宠物窝、家具场景和道具图标

暂不包含：

- 联机
- 局内进化
- 正式美术动画
- 安卓触屏操作

## 核心玩法

一局比赛中，猫队和狗队各有一个宠物窝，每个宠物窝有 5 点耐久。

核心目标很简单：

1. 冲向客厅中场抢 `罐头炸弹`。
2. 把 `罐头炸弹` 带进敌方宠物窝。
3. 每成功送入一次，敌方宠物窝耐久 -1。
4. 先把对方宠物窝拆到 0 的队伍获胜。

局内有 5 类道具：

| 道具 | 作用 |
| --- | --- |
| 罐头炸弹 | 带进敌方宠物窝，拆掉 1 点耐久 |
| 胶带卷 | 带回自家宠物窝，修复 1 点耐久 |
| 铃铛 | 拾取后短时间加速 |
| 抱枕盾 | 拾取后获得护盾，适合护送 |
| 臭袜子 | 按 `E` 投掷，命中敌人后减速 |

## 操作

| 操作 | 按键 |
| --- | --- |
| 移动 | `W A S D` 或方向键 |
| 拍打/踢道具 | `J` 或鼠标左键 |
| 使用技能 | `K` 或鼠标右键 |
| 使用手上道具 | `E` |
| 结算后返回准备页 | `Enter` 或空格 |

`J` 的含义：

- 贴近敌方宠物时，拍打敌人。
- 贴近地上道具时，把道具踢出去。

`K` 的含义：

- 每只宠物有一个主动技能。
- 橘猫/柴犬：冲刺。
- 三花/哈士奇：加速。
- 布偶：推开敌人。
- 柯基：护盾。

`E` 的含义：

- 手上拿 `臭袜子` 时，向附近敌人投掷。
- 手上拿 `罐头炸弹` 或 `胶带卷` 时，放下道具。
- 没拿道具时不会生效，靠近道具会自动拾取。

## 局外准备期

当前已经有一个最小准备期闭环：

1. 选择猫队或狗队。
2. 选择自己控制的宠物。
3. 开始 3v3 对局。
4. 对局结束后获得小鱼干。
5. 使用小鱼干升级宠物。

二阶进化暂时不放进局内，后续会放在准备期或养成系统里做。

## 本地运行

安装 Godot 4.6.x 后，用 Godot 打开本仓库根目录：

```text
project.godot
```

主场景：

```text
res://scenes/Main.tscn
```

也可以在仓库根目录用命令行做基础启动检查：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/Main.tscn --quit-after 3
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/Battle.tscn --quit-after 5
```

## Web 试玩

导出 Web 包：

```bash
bash tools/export_web.sh
```

启动本地 Web 服务：

```bash
python3 -m http.server 8765 --bind 127.0.0.1 --directory builds/web
```

打开：

```text
http://127.0.0.1:8765
```

不要直接用 `file://` 打开导出的 `index.html`，Godot Web 需要通过本地服务器访问。

更详细的导出说明见 `EXPORT.md`。

## 项目结构

```text
assets/
  fonts/          中文字体
  visuals/        SVG 原型美术资源
scenes/
  Main.tscn       准备页/选择页
  Battle.tscn     对局场景
scripts/
  Main.gd         准备页逻辑
  Battle.gd       对局规则、AI、HUD、输入
  Pet.gd          宠物属性、移动、攻击、技能
  Item.gd         道具拾取、投掷、表现
  Base.gd         猫窝/狗窝耐久
  GameData.gd     宠物配置
  GameState.gd    局外状态、金币、升级
tools/
  export_web.sh   Web 导出脚本
```

## 当前 AI

第一版 AI 已有基础分工：

- 进攻：优先抢罐头炸弹并送进敌方窝。
- 护送：靠近己方持有罐头炸弹的队友。
- 防守：敌方持有罐头炸弹靠近时优先拦截。
- 修复：自家宠物窝受损时会尝试找胶带卷。
- 道具：会拾取加速、护盾、臭袜子等辅助道具。

这还不是高智能 AI，但已经能支撑第一版可玩闭环。

## 当前限制

- 美术仍是原型级 SVG，不是最终角色建模/动画。
- 安卓端暂不做，触屏虚拟按钮目前在代码中隐藏。
- 联机暂不做，后续如果扩展联机，需要单独重构同步和权威判定。
- 局内进化暂不做，避免第一版规则过重。
- Web 端是当前主要试玩平台。

## 开发验证

常用检查：

```bash
git diff --check
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/Main.tscn --quit-after 3
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/Battle.tscn --quit-after 5
bash tools/export_web.sh
```

## 后续方向

优先级建议：

1. 重绘正式宠物角色和道具资源。
2. 强化攻击、投掷、技能动画反馈。
3. 调整客厅地图布局，让抢道具、护送、回防路线更清晰。
4. 优化 AI 分工，让队友护送和敌方防守更聪明。
5. 加入局外二阶进化展示。
6. 在 Web 版本稳定后，再考虑 Android 输入和打包。
