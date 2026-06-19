import SwiftUI
import SwiftData

@main
struct GiuseppeApp: App {
    @State private var themeManager = ThemeManager()
    @State private var soundManager = SoundManager()
    @State private var modelError: Error?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(themeManager.currentTheme.primaryColor)
                .environment(themeManager)
                .environment(soundManager)
                .alert("数据存储错误", isPresented: Binding(
                    get: { modelError != nil },
                    set: { if !$0 { modelError = nil } }
                )) {
                    Button("重试") { modelError = nil }
                } message: {
                    Text(modelError?.localizedDescription ?? "未知错误")
                }
        }
        .modelContainer(for: [
            Transaction.self,
            Category.self,
            SubCategory.self,
            Account.self,
            Budget.self,
            AssetSnapshot.self
        ]) { result in
            switch result {
            case .success(let container):
                SeedDataService.seedIfNeeded(context: container.mainContext)
            case .failure(let error):
                modelError = error
            }
        }
    }
}

// MARK: - 种子数据服务（后续可提取为独立文件）

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

// MARK: - SwiftData 迁移方案（v1.0 骨架，后续新增版本在此扩展）

/*
 当模型变更时（如添加/删除/重命名属性），按以下步骤操作：
 1. 创建 GiuseppeSchemaV2 复制当前所有模型
 2. 添加 MigrationStage（轻量或自定义迁移）
 3. 在 GiuseppeMigrationPlan.schemas 中追加新版本
 4. 在 GiuseppeApp.modelContainer 中传入 migrationPlan 参数

 使用示例：
  .modelContainer(
     for: [Transaction.self, ...],
     migrationPlan: GiuseppeMigrationPlan.self
  ) { result in ... }
*/

/*
enum GiuseppeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [] // 追加: GiuseppeSchemaV1.self, GiuseppeSchemaV2.self
    }
    static var stages: [MigrationStage] {
        [] // 追加: MigrationStage.lightweight(fromVersion: V1.self, toVersion: V2.self)
    }
}
*/
