import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Int            // 分
    var type: String           // "expense" | "income"
    var categoryId: UUID
    var subCategoryId: UUID?
    var accountId: UUID
    var date: Date
    var note: String?
    var imagePaths: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Int,
        type: String,
        categoryId: UUID,
        subCategoryId: UUID? = nil,
        accountId: UUID,
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
        self.date = date
        self.note = note
        self.imagePaths = imagePaths
        self.createdAt = Date()
    }
}
