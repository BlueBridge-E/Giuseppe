import Foundation
import SwiftData

@Model
final class SubCategory {
    var id: UUID
    var name: String
    var icon: String?
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, icon: String? = nil, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
    }
}

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String          // SF Symbol name
    var color: String         // hex
    var type: TransactionType // 使用枚举替代原来的 String
    var sortOrder: Int
    @Relationship(deleteRule: .cascade) var subCategories: [SubCategory]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "questionmark.circle",
        color: String = "007AFF",
        type: TransactionType = .expense,
        sortOrder: Int = 0,
        subCategories: [SubCategory] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.sortOrder = sortOrder
        self.subCategories = subCategories
    }
}
