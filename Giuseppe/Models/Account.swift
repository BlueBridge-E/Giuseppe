import Foundation
import SwiftData

/// 账户类型枚举，提供编译时安全
enum AccountType: String, Codable, CaseIterable {
    case cash        = "cash"
    case bank        = "bank"
    case credit      = "credit"
    case storedValue = "storedValue"
    case investment  = "investment"

    var isCredit: Bool { self == .credit }

    var displayName: String {
        switch self {
        case .cash:        "现金"
        case .bank:        "银行卡"
        case .credit:      "信用卡"
        case .storedValue: "储值卡"
        case .investment:  "投资账户"
        }
    }
}

@Model
final class Account {
    var id: UUID
    var name: String
    var type: AccountType
    var balance: Int           // 分
    var includeInTotalAsset: Bool
    var sortOrder: Int
    var creditLimit: Int?
    var billingDay: Int?
    var repaymentDay: Int?

    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType = .cash,
        balance: Int = 0,
        includeInTotalAsset: Bool? = nil,  // nil 时根据账户类型自动决定
        sortOrder: Int = 0,
        creditLimit: Int? = nil,
        billingDay: Int? = nil,
        repaymentDay: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        // 信用卡默认不计入总资产（因其 displayBalance 已为负值处理）
        self.includeInTotalAsset = includeInTotalAsset ?? (type != .credit)
        self.sortOrder = sortOrder
        self.creditLimit = creditLimit
        self.billingDay = billingDay
        self.repaymentDay = repaymentDay
    }

    var isCredit: Bool { type == .credit }
    var displayBalance: Int {
        isCredit ? -(balance) : balance
    }
}
