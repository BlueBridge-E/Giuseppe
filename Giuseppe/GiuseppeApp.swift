import SwiftUI
import SwiftData

@main
struct GiuseppeApp: App {
    @State private var themeManager = ThemeManager()
    @State private var soundManager = SoundManager()
    /// 手动创建 ModelContainer，升级时自动清理不兼容的旧数据库
    private let container: ModelContainer = {
        // 检查版本升级，清理旧库
        let currentDBVersion = 2
        let lastDBVersion = UserDefaults.standard.integer(forKey: "dbVersion")
        if lastDBVersion < currentDBVersion {
            let storeDir = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeDir)
            try? FileManager.default.removeItem(at: storeDir.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeDir.appendingPathExtension("shm"))
            UserDefaults.standard.set(currentDBVersion, forKey: "dbVersion")
        }
        // 创建容器
        let c = try! ModelContainer(
            for: Transaction.self, Category.self, SubCategory.self,
            Account.self, Budget.self, AssetSnapshot.self
        )
        SeedDataService.seedIfNeeded(context: c.mainContext)
        return c
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(themeManager.currentTheme.primaryColor)
                .environment(themeManager)
                .environment(soundManager)
                .modelContainer(container)
        }
    }
}

// MARK: - 种子数据服务

struct SeedDataService {
    static func seedIfNeeded(context: ModelContext) {
        seedDefaultCategories(context: context)
        seedDefaultAccounts(context: context)
    }

    private static func seedDefaultCategories(context: ModelContext) {
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
            context.insert(Category(name: cat.name, icon: cat.icon, color: cat.color, type: .expense, sortOrder: idx))
        }
        for (idx, cat) in incomeCategories.enumerated() {
            context.insert(Category(name: cat.name, icon: cat.icon, color: cat.color, type: .income, sortOrder: idx))
        }
    }

    private static func seedDefaultAccounts(context: ModelContext) {
        let descriptor = FetchDescriptor<Account>()
        guard (try? context.fetch(descriptor))?.isEmpty == true else { return }

        context.insert(Account(name: "现金", type: .cash, sortOrder: 0))
        context.insert(Account(name: "银行卡", type: .bank, sortOrder: 1))
    }
}

// 数据库版本管理：通过 UserDefaults dbVersion 标记，升级时自动清理旧库
// 未来如需真正的数据迁移（不删数据），再添加 VersionedSchema + MigrationPlan
