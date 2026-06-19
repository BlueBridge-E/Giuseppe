import Foundation
import SwiftData

/// 预算类型枚举，提供编译时安全
enum BudgetType: String, Codable, CaseIterable {
    case monthly = "monthly"
    case yearly  = "yearly"
}

@Model
final class Budget {
    var id: UUID
    var type: BudgetType
    var categoryId: UUID?
    var amount: Int           // 分
    var month: Int?           // 1-12
    var year: Int

    init(
        id: UUID = UUID(),
        type: BudgetType = .monthly,
        categoryId: UUID? = nil,
        amount: Int = 0,
        month: Int? = nil,
        year: Int = Calendar.current.component(.year, from: Date())
    ) {
        self.id = id
        self.type = type
        self.categoryId = categoryId
        self.amount = amount
        self.month = month
        self.year = year
    }
}
