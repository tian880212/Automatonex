# Automatonex — 个人修改版（Turtle WoW 1.12）

> **非官方修改版。** 基于 AutomatonEx 工具箱（原作者 **weab**，Ace2 插件，[WoWI 5610](https://www.wowinterface.com/downloads/info5610)），
> 中文强化版由 **黑猫插件**、**可可慕斯**、**最爱** 等人完成本地化与增强。
> 本仓库在该中文版基础上继续修改，面向 **Turtle WoW / WoW 1.12（Interface 11200）**。
> 版权归原作者与各位中文版贡献者所有；本仓库只做修改与分发，不主张任何新版权。

本仓库地址：<https://github.com/tian880212/Automatonex>

一套「自动化杂事」工具箱：自动换磨刀石 / 自动喝赞扎 / 自动下马 / 自动站立 /
自动接任务 / 自动确认拾取 / 副本重置计时 / 触发监控 / 聊天增强…… 一格一格勾选即可。

---

## 安装

1. 解压后的目录名必须是 **`Automatonex`**（与 `Automatonex.toc` 同级），不要带 `-main` 之类后缀
2. 整个目录放进 `Interface\AddOns\`
3. **需要同时安装公共库 `!Libs`**（提供 Ace2、AbacusLib、GratuityLib、SpecialEventsEmbed）
   —— 本仓库**不含**这些库，缺了会在登录时大量报错且界面打不开
4. 进游戏输入 `/auto`

## 常用命令

| 命令 | 作用 |
| --- | --- |
| `/auto`、`/automaton` | 打开主设置窗口 |
| `/autocl`、`/automatoncl` | 同上（旧别名） |

---

## 与原版的主要差异

### 设置界面（整体重做）

- **扁平风格**主窗口，**11 套预设主题色**（HSL 派生色阶，切换主题时原地刷新而不是重建窗口，
  避免残留孤儿 frame 导致的拖动掉帧与位置跳动）
- **背景透明度**滑块（0~100%），hover / press 状态色一并跟随，不会在半透明下变实心
- **模块启停保存范围可切**：按角色 / 按账户。切换时互拷当前状态，所见不变
- 修复「默认禁用」判据：原来读的是合并后的配置视图，被历史持久化的 `false` 遮住了代码里声明的
  默认值，导致新角色上本该默认关闭的模块全部默认开启
- 切换模块时保持滚动位置；隐藏模块单独归类；主页显示统计（总数 / 启用 / 禁用 / 隐藏）

### 新增或重写过的模块

- **ProcDoc** — 触发监控
- **CleanChat** — 聊天增强（`Plubics/CleanChat`）
- **Boomtime** — 副本重置计时：扁平化 + 标题栏 + 关闭按钮（关闭即按角色停用该模块）+ ESC 关闭
- **QuestAutomation** — 自定义任务自动接取 / 完成
- **AutoNeed** — 蓝装绿装 need / greed / 分解
- **WorldBuffs** — 世界 BOSS 冷却（每服 7 天）
- **CDSafe**、**RangeController**、**QuestItemBar**、**S_ActionCount**、**S_ItemLinktoenUS**、
  **TSTargetMark**、**jtlk**、**shiqu** 等

完整清单见 `Automatonex.toc`（60 余个模块，逐行加载）。

### 中文本地化

- 模块名与提示文案统一走 AceLocale 词条表；`enUS` 与 `zhCN` 必须成对补齐，
  只加一边会在加载时报 `Improper translation exists` 并让整个语言表失效
- 模块中文名速查（部分）：i人模式 = Loner、强制拾取 = shiqu、自动禁止移动 = jtlk、
  组队密语邀请 = Invite、组队自动进组 = Group、组队自动跟随 = Follow、
  自动显示飞行点旅馆 = AutoDB、团队就位确认 = Ready、团队拾取确认 = LootBOP、
  美观经验条 = ExpBar、技能与物品管理 = Lern2Spell、战斗记录范围控制器 = RangeController

### 针对 1.12 / Turtle 客户端的适配

- 本客户端 `OnUpdate` 回调的第 1 个参数直接就是 `elapsed` 数值，按此校正了一批计时点
- 中文客户端 `UnitClass("player")` 两个返回值都是本地化串（不是 `ROGUE` 这种英文名），
  职业判断一律走本地化表映射
- `FontString` / `Texture` 没有 `SetScript`，需要定时器的地方按 `CreateFrame("Frame")` 挂载

---

## 说明

- 这是**个人维护**的修改版，不保证与上游同步，也不对游戏内数据安全做额外承诺
- 报错请带 `Interface\AddOns\Automatonex` 下的完整文件路径与行号
- 上游问题请反馈给 AutomatonEx 原作者，不要提交到本仓库
