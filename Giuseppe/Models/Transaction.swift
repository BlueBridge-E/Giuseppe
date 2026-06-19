import Foundation
import SwiftData

/// 交易类型枚举，提供编译时安全
enum TransactionType: String, Codable, CaseIterable {
    case expense  = "expense"
    case income   = "income"
    case transfer = "transfer"
    case refund   = "refund"

    var isExpense: Bool { self == .expense }
    var isIncome: Bool { self == .income }
}

@Model
final class Transaction {
    var id: UUID
    var amount: Int              // 分
    var type: TransactionType
    var categoryId: UUID
    var subCategoryId: UUID?
    var accountId: UUID
    var toAccountId: UUID?       // 转账目标账户（v2 实现）
    var date: Date
    var note: String?
    var imagePaths: [String]
    var createdAt: Date
    var updatedAt: Date          // 记录最后修改时间

    init(
        id: UUID = UUID(),
        amount: Int,
        type: TransactionType,
        categoryId: UUID,
        subCategoryId: UUID? = nil,
        accountId: UUID,
        toAccountId: UUID? = nil,
        date: Date = Date(),
        note: String? = nil,
        imagePaths: [String] = []
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.categoryId = categoryId
        self.subCategoryId = subCategoryId
        self.accountId = accountId
        self.toAccountId = toAccountId
        self.date = date
        self.note = note
        self.imagePaths = imagePaths
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
