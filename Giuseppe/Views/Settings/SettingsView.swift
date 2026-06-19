import SwiftUI
import SwiftData

// MARK: - 预设图标与颜色

private let presetIcons: [String] = [
    "fork.knife", "car.fill", "bag.fill", "gamecontroller.fill", "house.fill",
    "cross.case.fill", "book.fill", "antenna.radiowaves.left.and.right",
    "dollarsign.circle", "star.fill", "briefcase.fill", "chart.line.uptrend.xyaxis",
    "doc.text.fill", "ellipsis.circle", "heart.fill", "airplane", "cart.fill",
    "gift.fill", "camera.fill", "pawprint.fill", "music.note", "figure.run",
    "cup.and.saucer.fill", "wrench.and.screwdriver.fill"
]

private let presetColors: [(name: String, hex: String)] = [
    ("红", "E74C3C"), ("橙", "FF6B35"), ("黄", "F39C12"), ("绿", "27AE60"),
    ("青", "1ABC9C"), ("蓝", "007AFF"), ("紫", "9B59B6"), ("粉", "E85D75"),
    ("灰", "95A5A6"), ("棕", "8B4513"), ("靛", "2980B9"), ("玫", "C2185B")
]

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(SoundManager.self) private var soundManager
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var transactions: [Transaction]
    @State private var lookbackDays: Int = UserDefaults.standard.integer(forKey: "wealthLookbackDays")
    @State private var csvExportURL: URL?

    private func exportCSV() -> URL? {
        let header = "日期,类型,分类,金额,备注\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let rows = transactions
            .sorted(by: { $0.date > $1.date })
            .map { txn -> String in
                let catName = categories.first(where: { $0.id == txn.categoryId })?.name ?? "未知"
                let typeStr = txn.type.isExpense ? "支出" : "收入"
                let amountStr = formatCents(txn.amount)
                let note = (txn.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(dateFormatter.string(from: txn.date))\",\(typeStr),\"\(catName)\",\(amountStr),\"\(note)\"\n"
            }

        let csv = header + rows.joined()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Giuseppe_\(Date().timeIntervalSince1970).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

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
                        .accessibilityAddTraits(themeManager.currentTheme == theme ? .isSelected : [])
                        .accessibilityLabel("\(theme.displayName)主题")
                        .accessibilityHint("双击选择此主题")
                        .onTapGesture { themeManager.currentTheme = theme }
                    }
                }

                Section("音效") {
                    Toggle("记账音效", isOn: Binding(
                        get: { soundManager.isSoundEnabled },
                        set: { soundManager.isSoundEnabled = $0 }
                    ))
                }

                Section("预算") {
                    NavigationLink("预算管理") { BudgetView() }
                }

                Section("分类管理") {
                    NavigationLink("支出分类") {
                        CategoryManageView(
                            categories: categories.filter { $0.type == .expense },
                            defaultType: .expense
                        )
                    }
                    NavigationLink("收入分类") {
                        CategoryManageView(
                            categories: categories.filter { $0.type == .income },
                            defaultType: .income
                        )
                    }
                }

                Section("财富支撑日") {
                    Stepper("统计天数: \(lookbackDays)天", value: $lookbackDays, in: 7...365, step: 1)
                        .onChange(of: lookbackDays) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "wealthLookbackDays")
                        }
                    Text("使用过去 \(lookbackDays) 天的日均支出计算")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("数据管理") {
                    Button("导出账单 CSV") {
                        csvExportURL = exportCSV()
                    }
                    if let url = csvExportURL {
                        ShareLink(item: url) {
                            Label("点击分享 CSV 文件", systemImage: "square.and.arrow.up")
                        }
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
            .onAppear {
                lookbackDays = UserDefaults.standard.integer(forKey: "wealthLookbackDays")
                if lookbackDays == 0 { lookbackDays = 30 }
            }
        }
    }
}

// MARK: - CategoryManageView（含新建 + 编辑 + 删除确认）

struct CategoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    let categories: [Category]
    let defaultType: TransactionType

    @State private var showingAddSheet = false
    @State private var editingCategory: Category?
    @State private var categoryToDelete: Category?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.color))
                    Text(category.name)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { editingCategory = category }
            }
            .onDelete { offsets in
                if let i = offsets.first {
                    categoryToDelete = categories[i]
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(defaultType.isExpense ? "支出分类" : "收入分类")
        .toolbar {
            Button { showingAddSheet = true } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CategoryFormSheet(
                title: "添加分类",
                defaultType: defaultType,
                categoriesCount: categories.count
            ) { name, icon, color in
                guard !name.isEmpty else { return }
                modelContext.insert(Category(
                    name: name, icon: icon, color: color,
                    type: defaultType, sortOrder: categories.count
                ))
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormSheet(
                title: "编辑分类",
                category: category,
                defaultType: defaultType,
                categoriesCount: categories.count
            ) { name, icon, color in
                guard !name.isEmpty else { return }
                category.name = name
                category.icon = icon
                category.color = color
            }
        }
        .confirmationDialog("确认删除", isPresented: $showingDeleteConfirmation, presenting: categoryToDelete) { cat in
            Button("删除", role: .destructive) { modelContext.delete(cat) }
            Button("取消", role: .cancel) { }
        } message: { cat in
            Text("确定要删除「\(cat.name)」吗？关联的交易将显示为未知分类。")
        }
    }
}

// MARK: - CategoryFormSheet（新建/编辑共用）

struct CategoryFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let defaultType: TransactionType
    let categoriesCount: Int
    let onSave: (String, String, String) -> Void

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String

    // 新建模式
    init(title: String, defaultType: TransactionType, categoriesCount: Int, onSave: @escaping (String, String, String) -> Void) {
        self.title = title
        self.defaultType = defaultType
        self.categoriesCount = categoriesCount
        self.onSave = onSave
        _name = State(initialValue: "")
        _selectedIcon = State(initialValue: "circle.fill")
        _selectedColor = State(initialValue: "007AFF")
    }

    // 编辑模式
    init(title: String, category: Category, defaultType: TransactionType, categoriesCount: Int, onSave: @escaping (String, String, String) -> Void) {
        self.title = title
        self.defaultType = defaultType
        self.categoriesCount = categoriesCount
        self.onSave = onSave
        _name = State(initialValue: category.name)
        _selectedIcon = State(initialValue: category.icon)
        _selectedColor = State(initialValue: category.color)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("分类名称", text: $name)

                // 图标选择
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(presetIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.2) : Color.clear)
                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                }

                // 颜色选择
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(presetColors, id: \.hex) { item in
                            Circle()
                                .fill(Color(hex: item.hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    selectedColor == item.hex
                                        ? Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.caption2)
                                        : nil
                                )
                                .onTapGesture { selectedColor = item.hex }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, selectedIcon, selectedColor)
                        dismiss()
                    }
                }
            }
        }
    }
}
