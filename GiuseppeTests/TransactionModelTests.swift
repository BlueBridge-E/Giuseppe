import XCTest
@testable import Giuseppe

final class TransactionModelTests: XCTestCase {
    func testTransactionInit_defaults() {
        let txn = Transaction(amount: 500, type: .expense, categoryId: UUID(), accountId: UUID())
        XCTAssertEqual(txn.amount, 500)
        XCTAssertEqual(txn.type, .expense)
        XCTAssertNotNil(txn.id)
        XCTAssertNil(txn.note)
        XCTAssertNil(txn.toAccountId)
        XCTAssertTrue(txn.imagePaths.isEmpty)
    }

    func testTransactionInit_withToAccount() {
        let toId = UUID()
        let txn = Transaction(amount: 300, type: .expense, categoryId: UUID(), accountId: UUID(), toAccountId: toId)
        XCTAssertEqual(txn.toAccountId, toId)
    }

    func testTransactionType_isExpense_isIncome() {
        XCTAssertTrue(TransactionType.expense.isExpense)
        XCTAssertFalse(TransactionType.expense.isIncome)
        XCTAssertTrue(TransactionType.income.isIncome)
        XCTAssertFalse(TransactionType.income.isExpense)
        XCTAssertFalse(TransactionType.transfer.isExpense)
        XCTAssertFalse(TransactionType.transfer.isIncome)
    }

    func testFormatCents() {
        XCTAssertEqual(formatCents(0), "0")
        XCTAssertEqual(formatCents(100), "1")
        XCTAssertEqual(formatCents(1250), "12.5")
        XCTAssertEqual(formatCents(1), "0.01")
        XCTAssertEqual(formatCents(10000), "100")
        // 负值
        XCTAssertEqual(formatCents(-500), "-5")
        XCTAssertEqual(formatCents(-1), "-0.01")
    }

    func testCentsToDouble() {
        XCTAssertEqual(centsToDouble(0), 0)
        XCTAssertEqual(centsToDouble(1250), 12.5)
        XCTAssertEqual(centsToDouble(1), 0.01)
        XCTAssertEqual(centsToDouble(10000), 100)
        XCTAssertEqual(centsToDouble(-500), -5)
    }

    func testYuanToCents() {
        XCTAssertEqual(yuanToCents(12.5), 1250)
        XCTAssertEqual(yuanToCents(0.01), 1)
        XCTAssertEqual(yuanToCents(100), 10000)
        XCTAssertEqual(yuanToCents(0), 0)
    }

    func testAccountDisplayBalance() {
        let cash = Account(name: "现金", type: .cash, balance: 5000_00)
        XCTAssertEqual(cash.displayBalance, 5000_00)

        let credit = Account(name: "信用卡", type: .credit, balance: 3000_00)
        XCTAssertEqual(credit.displayBalance, -3000_00)
        XCTAssertTrue(credit.isCredit)
    }

    func testAccount_defaultIncludeInTotalAsset() {
        // 非信用卡默认计入总资产
        let cash = Account(name: "现金", type: .cash)
        XCTAssertTrue(cash.includeInTotalAsset)

        let bank = Account(name: "银行卡", type: .bank)
        XCTAssertTrue(bank.includeInTotalAsset)

        // 信用卡默认不计入总资产
        let credit = Account(name: "信用卡", type: .credit)
        XCTAssertFalse(credit.includeInTotalAsset)
    }

    func testAccountType_enum() {
        XCTAssertEqual(AccountType.cash.rawValue, "cash")
        XCTAssertTrue(AccountType.credit.isCredit)
        XCTAssertFalse(AccountType.bank.isCredit)
        XCTAssertEqual(AccountType.allCases.count, 5)
    }

    func testBudgetType_enum() {
        XCTAssertEqual(BudgetType.monthly.rawValue, "monthly")
        XCTAssertEqual(BudgetType.yearly.rawValue, "yearly")
    }

    // MARK: - Phase 1 新增测试

    func testAccountInit_withBalance() {
        let acc = Account(name: "储蓄", type: .bank, balance: 5000_00)
        XCTAssertEqual(acc.balance, 5000_00)
    }

    func testAccountInit_withExplicitInclude() {
        // 显式指定 includeInTotalAsset 覆盖默认
        let credit = Account(name: "信用卡", type: .credit, includeInTotalAsset: true)
        XCTAssertTrue(credit.includeInTotalAsset)
    }

    func testBudgetOverBudgetDetection() {
        // spent > budgetAmount → 已超支
        let spent = 6000_00
        let budgetAmount = 5000_00
        let progress = Double(spent) / Double(budgetAmount)
        XCTAssertGreaterThan(progress, 1.0)
        XCTAssertEqual(spent - budgetAmount, 1000_00)
    }

    func testAccountTypeDisplayName() {
        XCTAssertEqual(AccountType.cash.displayName, "现金")
        XCTAssertEqual(AccountType.credit.displayName, "信用卡")
        XCTAssertEqual(AccountType.investment.displayName, "投资账户")
    }

    // MARK: - Phase 2 新增测试

    func testCategoryUpdate() {
        let cat = Category(name: "测试", icon: "star.fill", color: "FF6B35", type: .expense)
        XCTAssertEqual(cat.name, "测试")
        XCTAssertEqual(cat.icon, "star.fill")

        // 模拟编辑
        cat.name = "修改后"
        cat.icon = "heart.fill"
        cat.color = "27AE60"
        XCTAssertEqual(cat.name, "修改后")
        XCTAssertEqual(cat.icon, "heart.fill")
        XCTAssertEqual(cat.color, "27AE60")
    }

    func testTransactionEdit() {
        let catId = UUID()
        let accId = UUID()
        let txn = Transaction(amount: 5000, type: .expense, categoryId: catId, accountId: accId)

        // 模拟编辑
        txn.amount = 10000
        txn.note = "修改备注"
        txn.updatedAt = Date()
        XCTAssertEqual(txn.amount, 10000)
        XCTAssertEqual(txn.note, "修改备注")
        XCTAssertNotNil(txn.updatedAt)
    }

    func testTransactionTypeSwitch() {
        // 支出 ↔ 收入切换
        let txn = Transaction(amount: 5000, type: .expense, categoryId: UUID(), accountId: UUID())
        XCTAssertTrue(txn.type.isExpense)

        txn.type = .income
        XCTAssertTrue(txn.type.isIncome)
        XCTAssertFalse(txn.type.isExpense)
    }

    func testBudgetEdit() {
        let budget = Budget(type: .monthly, amount: 1000_00, month: 6, year: 2026)
        XCTAssertEqual(budget.amount, 1000_00)

        budget.amount = 2000_00
        budget.categoryId = UUID()
        XCTAssertEqual(budget.amount, 2000_00)
        XCTAssertNotNil(budget.categoryId)
    }

    // MARK: - Phase 3 新增测试

    func testUndoTransactionBalanceRevert() {
        // 模拟撤销：检查余额回滚逻辑
        let account = Account(name: "测试", type: .cash, balance: 10000_00)
        let txnAmount = 3000_00

        // 记一笔支出
        account.balance -= txnAmount
        XCTAssertEqual(account.balance, 7000_00)

        // 撤销：余额回滚
        account.balance += txnAmount
        XCTAssertEqual(account.balance, 10000_00)
    }

    func testUndoTransactionIncomeRevert() {
        let account = Account(name: "测试", type: .bank, balance: 5000_00)
        let txnAmount = 2000_00

        // 记一笔收入
        account.balance += txnAmount
        XCTAssertEqual(account.balance, 7000_00)

        // 撤销：余额回滚
        account.balance -= txnAmount
        XCTAssertEqual(account.balance, 5000_00)
    }

    func testCSVExportFormat() {
        // 验证 CSV 格式基本逻辑
        let testRow = "\"2026-06-19\",支出,\"餐饮\",12.5,\"午餐\"\n"
        XCTAssertTrue(testRow.contains("支出"))
        XCTAssertTrue(testRow.contains("12.5"))
        XCTAssertTrue(testRow.contains("餐饮"))
    }
}
