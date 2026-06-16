import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var type: String        // "cash"|"bank"|"credit"|"storedValue"|"investment"
    var balance: Int        // 分
    var includeInTotalAsset: Bool
    var sortOrder: Int
    var creditLimit: Int?
    var billingDay: Int?
    var repaymentDay: Int?

    init(
        id: UUID = UUID(),
        name: String,
        type: String = "cash",
        balance: Int = 0,
        includeInTotalAsset: Bool = true,
        sortOrder: Int = 0,
        creditLimit: Int? = nil,
        billingDay: Int? = nil,
        repaymentDay: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.includeInTotalAsset = includeInTotalAsset
        self.sortOrder = sortOrder
        self.creditLimit = creditLimit
        self.billingDay = billingDay
        self.repaymentDay = repaymentDay
    }

    var isCredit: Bool { type == "credit" }
    var displayBalance: Int {
        isCredit ? -(balance) : balance
    }
}
