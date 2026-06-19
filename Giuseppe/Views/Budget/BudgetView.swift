import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]
    @Query private var transactions: [Transaction]
    @State private var showingAddSheet = false
    @State private var editingBudget: Budget?

    var body: some View {
        List {
            Section("月度总预算") {
                let totalBudgets = budgets.filter { $0.type == .monthly && $0.categoryId == nil }
                ForEach(totalBudgets) { budget in
                    let (spent, catName) = computeSpentAndName(for: budget)
                    BudgetRow(spent: spent, categoryName: catName, budgetAmount: budget.amount)
                        .contentShape(Rectangle())
                        .onTapGesture { editingBudget = budget }
                }
                if totalBudgets.isEmpty {
                    Text("暂无总预算")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            Section("分类预算") {
                let catBudgets = budgets.filter { $0.categoryId != nil }
                ForEach(catBudgets) { budget in
                    let (spent, catName) = computeSpentAndName(for: budget)
                    BudgetRow(spent: spent, categoryName: catName, budgetAmount: budget.amount)
                        .contentShape(Rectangle())
                        .onTapGesture { editingBudget = budget }
                }
                if catBudgets.isEmpty {
                    Text("暂无分类预算")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("预算")
        .toolbar {
            Button { showingAddSheet = true } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBudgetSheet(categories: categories) { amount, categoryId in
                let budget = Budget(
                    type: .monthly,
                    categoryId: categoryId,
                    amount: yuanToCents(amount),
                    month: Calendar.current.component(.month, from: Date())
                )
                modelContext.insert(budget)
            }
        }
        .sheet(item: $editingBudget) { budget in
            EditBudgetSheet(budget: budget, categories: categories) { amount, categoryId in
                budget.amount = yuanToCents(amount)
                budget.categoryId = categoryId
            }
        }
    }

    // MARK: - 父级统一计算 spent

    private func computeSpentAndName(for budget: Budget) -> (spent: Int, categoryName: String) {
        let calendar = Calendar.current
        let now = Date()
        let month = budget.month ?? calendar.component(.month, from: now)
        let year = budget.year
        let components = DateComponents(year: year, month: month, day: 1)
        guard let monthStart = calendar.date(from: components) else { return (0, "总计") }
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now

        let matching = transactions.filter { txn in
            txn.date >= monthStart && txn.date < nextMonth && txn.type == .expense
        }

        let spent: Int
        if let catId = budget.categoryId {
            spent = matching.filter { $0.categoryId == catId }.reduce(0) { $0 + $1.amount }
        } else {
            spent = matching.reduce(0) { $0 + $1.amount }
        }

        let catName: String
        if let catId = budget.categoryId,
           let cat = categories.first(where: { $0.id == catId }) {
            catName = cat.name
        } else {
            catName = "总计"
        }

        return (spent, catName)
    }
}

// MARK: - BudgetRow（纯展示）

struct BudgetRow: View {
    let spent: Int
    let categoryName: String
    let budgetAmount: Int

    private var rawProgress: Double {
        budgetAmount > 0 ? Double(spent) / Double(budgetAmount) : 0
    }

    private var clampedProgress: Double { min(rawProgress, 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(categoryName).font(.subheadline)
                Spacer()
                Text("\(formatCents(spent)) / \(formatCents(budgetAmount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(rawProgress > 1.0 ? .red : rawProgress > 0.8 ? .red : rawProgress > 0.6 ? .orange : .green)
                        .frame(width: geo.size.width * clampedProgress)
                }
            }
            .frame(height: 8)

            if rawProgress > 1.0 {
                Text("已超支 \(formatCents(spent - budgetAmount))")
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else if rawProgress > 0.8 {
                Text("即将超支")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(categoryName)预算")
        .accessibilityValue(rawProgress > 1.0
            ? "已超支\(formatCents(spent - budgetAmount))元"
            : "已使用\(Int(rawProgress * 100))%，\(formatCents(spent))元 / \(formatCents(budgetAmount))元")
    }
}

// MARK: - AddBudgetSheet

struct AddBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [Category]
    let onSave: (Double, UUID?) -> Void

    @State private var amount = ""
    @State private var selectedCategoryId: UUID?

    var body: some View {
        NavigationStack {
            Form {
                TextField("预算金额", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("分类", selection: $selectedCategoryId) {
                    Text("总计").tag(UUID?.none)
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat.id)
                    }
                }
            }
            .navigationTitle("新增预算")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let amt = Double(amount), amt > 0 {
                            onSave(amt, selectedCategoryId)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - EditBudgetSheet

struct EditBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss
    var budget: Budget
    let categories: [Category]
    let onSave: (Double, UUID?) -> Void

    @State private var amount: String
    @State private var selectedCategoryId: UUID?

    init(budget: Budget, categories: [Category], onSave: @escaping (Double, UUID?) -> Void) {
        self.budget = budget
        self.categories = categories
        self.onSave = onSave
        _amount = State(initialValue: formatCents(budget.amount))
        _selectedCategoryId = State(initialValue: budget.categoryId)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("预算金额", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("分类", selection: $selectedCategoryId) {
                    Text("总计").tag(UUID?.none)
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat.id)
                    }
                }
            }
            .navigationTitle("编辑预算")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("更新") {
                        if let amt = Double(amount), amt > 0 {
                            onSave(amt, selectedCategoryId)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
