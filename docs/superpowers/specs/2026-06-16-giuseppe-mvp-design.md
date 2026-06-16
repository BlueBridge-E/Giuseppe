# Giuseppe MVP — 第一版设计文档

日期：2026-06-16 | 状态：已确认

## 概述

Giuseppe 是一款 iOS 原生记账应用，核心理念是"财富支撑日"（存款 ÷ 日均支出）。第一版（v1.0）聚焦基础记账 + 财富支撑日核心体验。

## 技术决策

| 决策 | 选择 |
|------|------|
| 语言 | Swift |
| UI | SwiftUI |
| 数据存储 | SwiftData |
| 最低部署 | iOS 17.0 |
| 金额存储 | Int（分），精确无浮点误差 |
| ViewModel | `@Observable` macro |
| 主题 | 四色可选，`@AppStorage` 持久化 |

## 导航结构

底部 TabView 四 Tab，首页即记账：

- **记账 Tab**：财富支撑日卡片 + 金额输入 + 分类选择网格 + 最近账单
- **统计 Tab**：饼图 + 折线图 + 趋势分析
- **资产 Tab**：账户列表 + 总资产饼图 + 负债管理
- **设置 Tab**：主题切换 / 分类管理 / 预算 / 音效开关 / 月起止日期

## 数据模型

```
Transaction (@Model)
  - id: UUID
  - amount: Int            # 单位：分
  - type: String           # expense / income
  - categoryId: UUID
  - subCategoryId: UUID?
  - accountId: UUID
  - date: Date
  - note: String?
  - imagePaths: [String]
  - createdAt: Date

Category (@Model)
  - id: UUID
  - name: String
  - icon: String           # SF Symbol name
  - color: String          # hex
  - type: String           # expense / income
  - sortOrder: Int
  - subCategories: [SubCategory]

SubCategory (@Model)
  - id: UUID
  - name: String
  - icon: String?
  - sortOrder: Int

Account (@Model)
  - id: UUID
  - name: String
  - type: String           # cash / bank / credit / storedValue / investment
  - balance: Int           # 分
  - includeInTotalAsset: Bool
  - sortOrder: Int
  - creditLimit: Int?
  - billingDay: Int?
  - repaymentDay: Int?

Budget (@Model)
  - id: UUID
  - type: String           # monthly / yearly
  - categoryId: UUID?
  - amount: Int            # 分
  - month: Int?
  - year: Int

AssetSnapshot (@Model)
  - id: UUID
  - date: Date
  - totalAsset: Int        # 分
  - totalLiability: Int    # 分
```

## 主题系统

四色主题，默认经典蓝：

```swift
enum AppTheme: String, CaseIterable {
    case blue    // #007AFF 经典蓝
    case green   // #34C759 财富绿
    case teal    // #5AC8FA 青蓝
    case amber   // #FF9500 暖金
}
```

通过 `ThemeManager`（`@Observable`）统一管理，`@AppStorage("appTheme")` 持久化。

## 财富支撑日计算

```
可支撑天数 = 总资产（分） ÷ 近N天日均支出（分）
```

- 分子：所有 `includeInTotalAsset = true` 的账户余额总和
- 分母：近 N 天（默认 30）支出总和 ÷ N
- 显示精确到 0.1 天
- 状态标签：>365 财务自由可期 / 180-365 很安全 / 90-180 较安全 / 30-90 需要注意 / <30 警戒

## 音效

- 支出：短促清脆"叮"，`expense_ding.mp3`
- 收入：稍长上扬"叮铃"，`income_ding.mp3`
- `SoundManager` 管理播放，AVAudioPlayer 实现
- 设置中可开关，默认开启

## 实现阶段

| Phase | 内容 | 产出 |
|-------|------|------|
| 1 | 项目骨架 + TabView 四Tab + 主题系统 | 可编译运行 |
| 2 | SwiftData 全部模型 + PreviewContainer | 数据层就绪 |
| 3 | 记账功能（金额输入 + 分类选择 + 存储 + 音效） | 可以记账 |
| 4 | 财富支撑日（计算服务 + 首页卡片展示） | 核心锚点数字 |
| 5 | 统计（饼图/折线图组件 + 统计页） | 可视化 |
| 6 | 资产管理（账户 CRUD + 总资产视图） | 账户管理 |
| 7 | 预算管理（预算 CRUD + 超支提醒） | 预算功能 |
| 8 | 设置收尾（主题切换/音效开关/自定义设置） | 完整设置 |

每 Phase 完成后执行 `xcodebuild` 编译验证 + 运行测试。

## 参考

- 钱迹：极简 UI、秒开模式、多账本
- 鲨鱼记账：音效反馈设计
