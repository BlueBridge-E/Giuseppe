import SwiftUI
import SwiftData

@main
struct GiuseppeApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(themeManager.currentTheme.primaryColor)
                .environment(themeManager)
        }
        .modelContainer(for: [
            Transaction.self,
            Category.self,
            Account.self,
            Budget.self,
            AssetSnapshot.self
        ]) { result in
            if case .success(let container) = result {
                seedDefaults(context: container.mainContext)
            }
        }
    }

    private func seedDefaults(context: ModelContext) {
        seedDefaultCategories(context: context)
        seedDefaultAccounts(context: context)
    }

    private func seedDefaultCategories(context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        guard (try? context.fetch(descriptor))?.isEmpty == true else { return }

        let expenseCategories: [(name: String, icon: String, color: String)] = [
            ("餐饮", "fork.knife", "FF6B35"),
            ("交通", "car.fill", "4A90D9"),
            ("购物", "bag.fill", "E85D75"),
            ("娱乐", "gamecontroller.fill", "9B59B6"),
            ("居家", "house.fill", "52B788"),
            ("医疗", "cross.case.fill", "E74C3C"),
            ("教育", "book.fill", "F39C12"),
            ("通讯", "antenna.radiowaves.left.and.right", "3498DB"),
        ]

        let incomeCategories: [(name: String, icon: String, color: String)] = [
            ("工资", "dollarsign.circle", "27AE60"),
            ("奖金", "star.fill", "F1C40F"),
            ("兼职", "briefcase.fill", "2ECC71"),
            ("投资", "chart.line.uptrend.xyaxis", "2980B9"),
            ("报销", "doc.text.fill", "95A5A6"),
            ("其他", "ellipsis.circle", "7F8C8D"),
        ]

        for (idx, cat) in expenseCategories.enumerated() {
            context.insert(Category(name: cat.name, icon: cat.icon, color: cat.color, type: "expense", sortOrder: idx))
        }
        for (idx, cat) in incomeCategories.enumerated() {
            context.insert(Category(name: cat.name, icon: cat.icon, color: cat.color, type: "income", sortOrder: idx))
        }
    }

    private func seedDefaultAccounts(context: ModelContext) {
        let descriptor = FetchDescriptor<Account>()
        guard (try? context.fetch(descriptor))?.isEmpty == true else { return }

        context.insert(Account(name: "现金", type: "cash", sortOrder: 0))
        context.insert(Account(name: "银行卡", type: "bank", sortOrder: 1))
    }
}
