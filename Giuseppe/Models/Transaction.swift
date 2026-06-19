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
    var id: UUID = UUID()
    var amount: Int = 0              // 分
    var type: TransactionType = TransactionType.expense
    var categoryId: UUID = UUID()
    var subCategoryId: UUID?
    var accountId: UUID = UUID()
    var toAccountId: UUID?           // 转账目标账户（v2 实现）
    var date: Date = Date()
    var note: String?
    var imagePaths: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()     // 有默认值，支持轻量迁移

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
