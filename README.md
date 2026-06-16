<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0%2B-007AFF?logo=apple&logoColor=white">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white">
  <img src="https://img.shields.io/badge/SwiftUI-✓-blue">
  <img src="https://img.shields.io/badge/SwiftData-✓-blue">
  <br>
  <img src="https://img.shields.io/badge/status-active-success">
  <img src="https://img.shields.io/badge/license-MIT-blue">
</p>

# Giuseppe

> 认清你的财富支撑日。每一笔收支背后，是多少天的自由。

Giuseppe 是一款 iOS 原生记账应用，用 **SwiftUI + SwiftData** 构建。它不只是一个记账工具，更是一面镜子——让你看清每花一笔钱，你的"财富支撑日"减少多少；每存一笔钱，你的自由度又增加了多少。

## 核心理念

### 财富支撑日

**当前资产余额 ÷ 日均支出 = 可支撑天数**

这个数字是你财富自由的锚。它不是财务公式，而是一种直觉——每次消费时，你都知道自己消耗了多少天的"自由"。

| 天数 | 状态 |
|------|------|
| > 365 天 | 财务自由可期 |
| 180–365 天 | 很安全 |
| 90–180 天 | 较安全 |
| 30–90 天 | 需要注意 |
| < 30 天 | 警戒 |

每一笔支出 → 数字减少 + 音效提醒，每存一笔钱 → 数字增长 + 正向反馈。让记账变成一种有体感的习惯。

## 设计原则

**极简，但有温度。**

- 界面干净留白，配色克制（主色 + 不超过 3 种辅助色）
- **打开即记**：三步完成一笔记账（打开 → 选分类 → 输金额 → 保存）
- 记账完成有音效反馈（支出"叮"提醒，收入"叮铃"正面激励），参考鲨鱼记账的交互设计
- 图标使用 SF Symbols，保持系统一致性
- **高度自定义**：一级/二级分类可自定义名称、图标、排序、颜色（参考钱迹的设计理念）

## 功能概览

| 功能 | 描述 |
|------|------|
| **记账** | 支出/收入，一级 + 二级分类体系，完全自定义 |
| **财富支撑日** | 首页顶部锚点数字，实时反馈每笔收支对自由天数的影响 |
| **多维度统计** | 饼图（分类占比）、折线图（趋势）、条形图（对比）；年/月/周/自定义区间 |
| **资产管理** | 现金/银行卡/信用卡/微信/支付宝/投资账户，资产趋势曲线，负债管理 |
| **预算管理** | 月度/年度/分类预算，日均预算动态更新，超支提醒 |
| **搜索** | 按金额、分类、备注、日期范围搜索历史账单 |
| **AI 分析（预留）** | 保留数据导出能力（JSON/CSV/Excel），架构预留接口，第一版暂不实现 |

## 技术栈

- **语言**：Swift 6.0
- **UI 框架**：SwiftUI
- **数据持久化**：SwiftData（iOS 17+）
- **依赖管理**：Swift Package Manager
- **最低部署目标**：iOS 17.0
- **开发工具**：Claude Code（编写 + 编译）+ Xcode（预览 + 真机调试）

## 项目结构

```
Giuseppe/
├── Giuseppe.xcodeproj/
├── CLAUDE.md                   # Claude Code 项目上下文
├── Giuseppe/
│   ├── GiuseppeApp.swift       # App 入口
│   ├── ContentView.swift       # 根视图
│   ├── Models/                 # SwiftData 模型
│   │   ├── Transaction.swift
│   │   ├── Category.swift
│   │   ├── Account.swift
│   │   ├── Budget.swift
│   │   └── AssetSnapshot.swift
│   ├── Services/               # 业务逻辑层
│   │   ├── WealthSupportDayService.swift
│   │   ├── BudgetService.swift
│   │   ├── StatisticsService.swift
│   │   └── AnalysisService.swift  # AI 分析预留
│   ├── Views/                  # UI 层
│   │   ├── Home/
│   │   ├── Recording/
│   │   ├── Statistics/
│   │   ├── Assets/
│   │   ├── Budget/
│   │   └── Settings/
│   ├── Components/             # 可复用组件
│   ├── Utilities/              # 工具类（音效、日期、格式化）
│   └── Resources/
│       ├── Assets.xcassets/
│       └── Audio/              # 音效文件
├── GiuseppeTests/
└── GiuseppeUITests/
```

## 第一版范围（MVP）

- [x] 基础记账（支出/收入）
- [x] 自定义分类体系（一级 + 二级）
- [x] 账户管理（现金/银行卡/信用卡）
- [x] 财富支撑日核心展示
- [x] 记账音效反馈
- [x] 月度统计（饼图 + 折线图）
- [x] 资产总览
- [x] 预算管理（月度总预算）
- [ ] 转账/退款/报销（后续版本）
- [ ] 周期记账（后续版本）
- [ ] AI 分析（预留接口）
- [ ] 共享账本（后续版本）
- [ ] iCloud 同步（后续版本）

## 许可证

MIT
