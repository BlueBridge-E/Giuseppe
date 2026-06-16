import XCTest
@testable import Giuseppe

final class TransactionModelTests: XCTestCase {
    func testTransactionInit_defaults() {
        let txn = Transaction(amount: 500, type: "expense", categoryId: UUID(), accountId: UUID())
        XCTAssertEqual(txn.amount, 500)
        XCTAssertEqual(txn.type, "expense")
        XCTAssertNotNil(txn.id)
        XCTAssertNil(txn.note)
        XCTAssertTrue(txn.imagePaths.isEmpty)
    }

    func testFormatCents() {
        XCTAssertEqual(formatCents(0), "0")
        XCTAssertEqual(formatCents(100), "1")
        XCTAssertEqual(formatCents(1250), "12.5")
        XCTAssertEqual(formatCents(1), "0.01")
        XCTAssertEqual(formatCents(10000), "100")
    }

    func testYuanToCents() {
        XCTAssertEqual(yuanToCents(12.5), 1250)
        XCTAssertEqual(yuanToCents(0.01), 1)
        XCTAssertEqual(yuanToCents(100), 10000)
    }

    func testAccountDisplayBalance() {
        let cash = Account(name: "现金", type: "cash", balance: 5000_00)
        XCTAssertEqual(cash.displayBalance, 5000_00)

        let credit = Account(name: "信用卡", type: "credit", balance: 3000_00)
        XCTAssertEqual(credit.displayBalance, -3000_00)
        XCTAssertTrue(credit.isCredit)
    }
}
