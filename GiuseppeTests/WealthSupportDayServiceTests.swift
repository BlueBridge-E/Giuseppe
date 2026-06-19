import XCTest
@testable import Giuseppe

final class WealthSupportDayServiceTests: XCTestCase {
    let service = WealthSupportDayService()

    // MARK: - Core calculation tests

    func testCalculateSupportDays_withTransactions_returnsCorrectValue() {
        // 总资产 10000 元，3 天支出 100+200+300=600 元，日均 200，支撑 10000/200=50 天
        let accounts = [
            makeAccount(name: "储蓄卡", balance: 10000_00, include: true),
        ]
        let txns = [
            makeTransaction(amount: 100_00, type: .expense, daysAgo: 0),
            makeTransaction(amount: 200_00, type: .expense, daysAgo: 1),
            makeTransaction(amount: 300_00, type: .expense, daysAgo: 2),
        ]
        service.lookbackDays = 3

        let result = service.calculateSupportDays(accounts: accounts, transactions: txns)
        XCTAssertEqual(result, 50.0, accuracy: 0.1)
    }

    func testCalculateSupportDays_noExpenses_returnsMax() {
        let accounts = [makeAccount(name: "储蓄卡", balance: 5000_00, include: true)]
        let result = service.calculateSupportDays(accounts: accounts, transactions: [])
        XCTAssertEqual(result, 9999.0, accuracy: 0.1)
    }

    func testCalculateSupportDays_noExpenses_noAssets_returnsZero() {
        // totalAsset == 0 且 dailyAvg == 0 → 返回 0
        let result = service.calculateSupportDays(accounts: [], transactions: [])
        XCTAssertEqual(result, 0.0, accuracy: 0.1)
    }

    func testCalculateSupportDays_excludedAccount_notCounted() {
        // includeInTotalAsset = false 的账户不应计入
        let accounts = [
            makeAccount(name: "储蓄卡", balance: 10000_00, include: true),
            makeAccount(name: "隐藏账户", balance: 50000_00, include: false),
        ]
        let txns = [
            makeTransaction(amount: 100_00, type: .expense, daysAgo: 0),
        ]
        service.lookbackDays = 1

        let result = service.calculateSupportDays(accounts: accounts, transactions: txns)
        // 仅 10000 元 / (100 元/天) = 100 天
        XCTAssertEqual(result, 100.0, accuracy: 0.1)
    }

    func testCalculateSupportDays_creditCardReducesAsset() {
        // 信用卡 displayBalance 为负，应减少总资产
        let accounts = [
            makeAccount(name: "储蓄卡", balance: 10000_00, include: true),
            makeAccount(name: "信用卡", type: .credit, balance: 3000_00, include: true),
        ]
        let txns = [
            makeTransaction(amount: 100_00, type: .expense, daysAgo: 0),
        ]
        service.lookbackDays = 1

        let result = service.calculateSupportDays(accounts: accounts, transactions: txns)
        // 总资产: 10000 - 3000 = 7000 元 / 100 元/天 = 70 天
        XCTAssertEqual(result, 70.0, accuracy: 0.1)
    }

    func testCalculateSupportDays_incomeTransactions_notCounted() {
        // 收入不应影响日均支出
        let accounts = [makeAccount(name: "储蓄卡", balance: 5000_00, include: true)]
        let txns = [
            makeTransaction(amount: 500_00, type: .expense, daysAgo: 0),
            makeTransaction(amount: 10000_00, type: .income, daysAgo: 0),
        ]
        service.lookbackDays = 1

        let result = service.calculateSupportDays(accounts: accounts, transactions: txns)
        // 仅计算支出: 5000 / 500 = 10 天
        XCTAssertEqual(result, 10.0, accuracy: 0.1)
    }

    // MARK: - Status label tests

    func testStatusLabel_ranges() {
        let cases: [(Double, String)] = [
            (400, "🟢 财务自由可期"),
            (200, "🟢 很安全"),
            (120, "🟡 较安全"),
            (60,  "🟠 需要注意"),
            (10,  "🔴 警戒"),
        ]
        for (days, expected) in cases {
            XCTAssertEqual(service.statusLabel(for: days).text, expected)
        }
    }

    func testStatusLabel_boundaries() {
        // 边界值测试
        XCTAssertEqual(service.statusLabel(for: 29.9).text, "🔴 警戒")
        XCTAssertEqual(service.statusLabel(for: 30.0).text, "🟠 需要注意")
        XCTAssertEqual(service.statusLabel(for: 89.9).text, "🟠 需要注意")
        XCTAssertEqual(service.statusLabel(for: 90.0).text, "🟡 较安全")
        XCTAssertEqual(service.statusLabel(for: 179.9).text, "🟡 较安全")
        XCTAssertEqual(service.statusLabel(for: 180.0).text, "🟢 很安全")
        XCTAssertEqual(service.statusLabel(for: 364.9).text, "🟢 很安全")
        XCTAssertEqual(service.statusLabel(for: 365.0).text, "🟢 财务自由可期")
    }

    func testStatusLabel_negativeDays() {
        // 负值 → danger
        let result = service.statusLabel(for: -5)
        XCTAssertEqual(result.text, "🔴 警戒")
    }

    // MARK: - Helpers

    private func makeAccount(
        name: String,
        type: AccountType = .bank,
        balance: Int,
        include: Bool
    ) -> Account {
        Account(name: name, type: type, balance: balance, includeInTotalAsset: include)
    }

    private func makeTransaction(amount: Int, type: TransactionType, daysAgo: Int) -> Transaction {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return Transaction(amount: amount, type: type, categoryId: UUID(), accountId: UUID(), date: date)
    }
}
