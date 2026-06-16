import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var soundManager = SoundManager()
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    var body: some View {
        NavigationStack {
            Form {
                Section("主题") {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        HStack {
                            Circle()
                                .fill(theme.primaryColor)
                                .frame(width: 20, height: 20)
                            Text(theme.displayName)
                            Spacer()
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { themeManager.currentTheme = theme }
                    }
                }

                Section("音效") {
                    Toggle("记账音效", isOn: $soundManager.isSoundEnabled)
                }

                Section("预算") {
                    NavigationLink("预算管理") {
                        BudgetView()
                    }
                }

                Section("分类管理") {
                    NavigationLink("支出分类") {
                        CategoryManageView(
                            categories: categories.filter { $0.type == "expense" }
                        )
                    }
                    NavigationLink("收入分类") {
                        CategoryManageView(
                            categories: categories.filter { $0.type == "income" }
                        )
                    }
                }

                Section("财富支撑日") {
                    HStack {
                        Text("统计天数")
                        Spacer()
                        Text("30天")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

struct CategoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    let categories: [Category]
    @State private var showingAddAlert = false
    @State private var newCategoryName = ""

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.color))
                    Text(category.name)
                }
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(categories[i]) }
            }
        }
        .toolbar {
            Button("添加") { showingAddAlert = true }
        }
        .alert("添加分类", isPresented: $showingAddAlert) {
            TextField("分类名称", text: $newCategoryName)
            Button("取消", role: .cancel) { }
            Button("添加") {
                guard !newCategoryName.isEmpty else { return }
                let type = categories.first?.type ?? "expense"
                modelContext.insert(Category(
                    name: newCategoryName, icon: "circle.fill",
                    color: "007AFF", type: type,
                    sortOrder: categories.count
                ))
                newCategoryName = ""
            }
        }
    }
}
