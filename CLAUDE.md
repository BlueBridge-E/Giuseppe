# Giuseppe — 个人记账 App
沟通语言：中文
## 项目概述

Giuseppe 是一款 iOS 原生记账应用，使用 SwiftUI + SwiftData 构建。核心理念是帮助用户认清自己的**财富支撑日**（存款 ÷ 日均支出），让每一笔收支都有直观的反馈。

## 当前状态

项目已进入 **v1.0 MVP 完成阶段**。Xcode 项目、Swift 源码均已创建，所有核心功能已实现并通过测试。下一步是功能迭代和打磨。

## 技术栈

- **语言**: Swift
- **UI**: SwiftUI
- **数据存储**: SwiftData（本地优先）
- **依赖管理**: Swift Package Manager
- **项目结构**: Xcode Project（.xcodeproj）
- **最低部署目标**: iOS 17.0+（SwiftData 要求）
- **开发工具**: Claude Code（写代码+编译）+ Xcode（预览+真机调试）

## 设计原则

### 总体风格 — 极简
- 界面干净、留白充足，不做花哨装饰
- 配色克制，主色用品牌色，辅助色系不超过 3 种
- 字体系统使用 SF Pro，层次分明（Large Title / Title / Body / Caption）
- 图标使用 SF Symbols，保持系统一致性
- 动画轻微自然，不做过度动效

### 交互原则
- 打开即记，减少点击次数（参考钱迹"秒开模式"）
- 核心路径：打开 App → 选分类 → 输金额 → 保存，三步以内完成
- 记账完成后立即播放反馈音效（参考鲨鱼记账"叮"的设计）
  - 支出：短促清脆的"叮"一声，提醒资金流出
  - 收入：稍长、上扬的"叮铃"声，给予正面反馈
  - 音效文件统一放在 `Assets/Audio/` 目录
  - 音效可设置开关，默认开启

### 自定义能力（参考钱迹）
- 一级/二级分类可自定义名称、图标、排序、颜色
- 账本可创建多个（日常/旅行/装修等）
- 月起止日期可自定义（非自然月）
- 账户资产可选择是否计入总资产
- 预算可设总计和分类预算

## 核心功能

### 1. 记账
- 支持：支出、收入、转账、退款、报销
- 分类体系：一级分类 + 二级分类，完全自定义
- 账户管理：现金、银行卡、信用卡、储值卡等
- 附件：每笔账单可添加图片（小票/凭证）
- 周期记账：房租/工资/订阅等固定收支自动生成
- 搜索：按金额、分类、备注、日期范围搜索

### 2. 财富支撑日（核心概念）
**定义**: 当前资产余额 ÷ 日均支出 = 可支撑天数

- **计算方式**:
  - 分子 = 所有资产账户余额总和（现金+存款+投资，不含信用卡负债）
  - 分母 = 过去 N 天的日均支出，N 用户可设置（默认 30 天）
  - 结果以天为单位显示，精确到 0.1 天
- **展示位置**:
  - 首页顶部醒目位置作为"锚点数字"
  - 显示格式："你的财富可支撑 **XX** 天"
  - 根据天数范围给出状态标签：
    - > 365 天：🟢 财务自由可期
    - 180-365 天：🟢 很安全
    - 90-180 天：🟡 较安全
    - 30-90 天：🟠 需要注意
    - < 30 天：🔴 警戒
- **实时反馈**:
  - 每记一笔支出 → 数字减少 + 音效反馈
  - 每记一笔收入 → 数字增加 + 音效反馈
  - 让用户直观感受到每笔消费消耗了多少"自由天数"

### 3. 多维度统计
- 时间维度：年 / 月 / 周 / 自定义区间
- 展示形式：饼图（分类占比）、折线图（趋势）、条形图（对比）
- 分类统计：单个分类的明细、占比、趋势
- 资产曲线：总资产随时间变化趋势图
- 复盘能力：账单列表支持日历视图和列表视图，可以直接在 App 内回顾，不需要切到其他笔记 App

### 4. 资产管理
- 账户类型：现金、银行卡、信用卡、储值卡、微信钱包、支付宝、投资账户
- 总资产视图：饼图展示各类资产占比
- 负债管理：信用卡待还、借款待还独立展示
- 资产负债总览表

### 5. 预算管理
- 月度预算 + 年度预算
- 分类预算（如"餐饮预算 2000/月"）
- 日均预算消耗动态更新
- 超支提醒

### 6. AI 分析（留接口，第一版不做）
- 保留数据导出的能力（JSON/CSV/Excel），为以后 AI 分析提供数据出口
- 不在第一版实现 AI 对话/分析功能
- 架构上预留 `AnalysisService` 协议，便于后续扩展

## 数据模型（核心）

```
Transaction
  - id: UUID
  - amount: Decimal
  - type: TransactionType (expense/income/transfer/refund)
  - categoryId: UUID
  - subCategoryId: UUID?
  - accountId: UUID
  - toAccountId: UUID? (用于转账)
  - date: Date
  - note: String?
  - imagePaths: [String]
  - createdAt: Date
  - updatedAt: Date

Category
  - id: UUID
  - name: String
  - icon: String (SF Symbol name)
  - color: String (hex)
  - type: TransactionType
  - sortOrder: Int
  - subCategories: [SubCategory]

SubCategory
  - id: UUID
  - name: String
  - icon: String?
  - sortOrder: Int

Account
  - id: UUID
  - name: String
  - type: AccountType (cash/bank/credit/storedValue/investment)
  - balance: Decimal
  - includeInTotalAsset: Bool
  - sortOrder: Int
  - creditLimit: Decimal? (信用卡)
  - billingDay: Int? (信用卡账单日)
  - repaymentDay: Int? (信用卡还款日)

Budget
  - id: UUID
  - type: BudgetType (monthly/yearly)
  - categoryId: UUID?
  - amount: Decimal
  - month: Int?
  - year: Int

AssetSnapshot (用于资产趋势图)
  - id: UUID
  - date: Date
  - totalAsset: Decimal
  - totalLiability: Decimal
```

注意：实际数据模型需要适配 SwiftData 的 `@Model` macro 要求，某些关系可能需要用 `@Relationship` 修饰。

## 项目结构

```
Giuseppe/
├── Giuseppe.xcodeproj/
├── CLAUDE.md (本文件)
├── .claude/                        # Claude Code 配置文件
│   └── settings.local.json         # 本地 MCP 等配置
├── Giuseppe/                       # 主 target
│   ├── GiuseppeApp.swift           # App 入口
│   ├── ContentView.swift           # 根视图
│   ├── Models/                     # SwiftData 模型
│   │   ├── Transaction.swift
│   │   ├── Category.swift
│   │   ├── Account.swift
│   │   ├── Budget.swift
│   │   └── AssetSnapshot.swift
│   ├── Services/                   # 业务逻辑
│   │   ├── WealthSupportDayService.swift  # 财富支撑日计算
│   │   ├── BudgetService.swift
│   │   ├── StatisticsService.swift
│   │   └── AnalysisService.swift       # AI 分析预留接口
│   ├── Views/                      # UI 视图
│   │   ├── Home/                   # 首页（财富支撑日 + 快捷记账入口）
│   │   ├── Recording/              # 记账视图
│   │   ├── Statistics/             # 统计页
│   │   ├── Assets/                 # 资产管理
│   │   ├── Budget/                 # 预算管理
│   │   └── Settings/               # 设置
│   ├── Components/                 # 可复用组件
│   │   ├── CategoryPicker.swift
│   │   ├── AmountInput.swift
│   │   ├── AccountPicker.swift
│   │   ├── PieChartView.swift
│   │   ├── LineChartView.swift
│   │   └── ...
│   ├── Utilities/                  # 工具类
│   │   ├── SoundManager.swift      # 音效管理
│   │   ├── DateHelper.swift
│   │   └── NumberFormatter.swift
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── Audio/                  # 音效文件
│   │       ├── expense_ding.mp3    # 支出音效
│   │       └── income_ding.mp3     # 收入音效
│   └── Preview Content/
├── GiuseppeTests/
└── GiuseppeUITests/
```

## 开发规范

### 代码风格
- 使用 `let` 优先于 `var`
- 使用 Swift 命名规范（camelCase 变量，PascalCase 类型）
- View 使用 `private` 访问级别，避免暴露内部状态
- 使用 `MARK:` 注释组织代码段

### SwiftUI 规范
- 每个 View 至少拆到文件级别，不写上千行的巨型 View
- ViewModel 使用 `@Observable` macro（iOS 17+）
- 数据流：`@Query` 读 SwiftData → ViewModel 处理逻辑 → View 渲染
- 使用 `@Environment(\.modelContext)` 操作数据

### 编译与测试

```bash
# 编译（选择可用的模拟器）
xcodebuild -project Giuseppe.xcodeproj -scheme Giuseppe -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# 如果 iPhone 16 Pro 不可用，列出已安装的模拟器
xcrun simctl list devices available

# 运行单元测试
xcodebuild test -project Giuseppe.xcodeproj -scheme Giuseppe -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# 运行单个测试
xcodebuild test -project Giuseppe.xcodeproj -scheme Giuseppe -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:GiuseppeTests/TestClassName/testMethodName

# 运行 UI 测试
xcodebuild test -project Giuseppe.xcodeproj -scheme GiuseppeUITests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

- Xcode 用于预览 Canvas 和真机调试
- 编译错误优先自查，无法修复的再建 Xcode 项目

### 版本管理
- 使用 Git，语义化版本
- commit message 中文，说明本次改动
- 第一版目标：v1.0 基础记账 + 财富支撑日 + 统计

## 参考 App

- **钱迹**: UI 风格参考（极简、自定义能力强、多账本、秒开模式）
- **鲨鱼记账**: 音效反馈参考（支出"叮"一声，增加记账仪式感）

## 第一版范围（MVP）

第一版只做以下功能，其余留后续版本：

- [x] 基础记账（支出/收入）
- [x] 自定义分类体系（一级+二级）
- [x] 账户管理（现金/银行卡/信用卡）
- [x] 财富支撑日核心展示
- [x] 记账音效反馈
- [x] 月度统计（饼图+折线图）
- [x] 资产总览
- [x] 预算管理（月度总预算）
- [ ] ~~转账/退款/报销~~（后续）
- [ ] ~~周期记账~~（后续）
- [ ] ~~AI 分析~~（留接口，后续）
- [ ] ~~共享账本~~（后续）
- [ ] ~~iCloud 同步~~（后续）
