import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]
    @Query private var transactions: [Transaction]
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section("月度总预算") {
                ForEach(budgets.filter { $0.type == "monthly" && $0.categoryId == nil }) { budget in
                    BudgetRow(budget: budget, categories: categories, transactions: transactions)
                }
                if budgets.filter({ $0.type == "monthly" && $0.categoryId == nil }).isEmpty {
                    Text("暂无总预算")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            Section("分类预算") {
                ForEach(budgets.filter { $0.categoryId != nil }) { budget in
                    BudgetRow(budget: budget, categories: categories, transactions: transactions)
                }
                if budgets.filter({ $0.categoryId != nil }).isEmpty {
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
                    type: "monthly",
                    categoryId: categoryId,
                    amount: yuanToCents(amount),
                    month: Calendar.current.component(.month, from: Date())
                )
                modelContext.insert(budget)
            }
        }
    }
}

struct BudgetRow: View {
    let budget: Budget
    let categories: [Category]
    let transactions: [Transaction]

    var categoryName: String {
        guard let catId = budget.categoryId,
              let cat = categories.first(where: { $0.id == catId })
        else { return "总计" }
        return cat.name
    }

    var spent: Int {
        let now = Date()
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        return transactions
            .filter { $0.date >= monthStart && $0.type == "expense" }
            .filter { budget.categoryId == nil || $0.categoryId == budget.categoryId }
            .reduce(0) { $0 + $1.amount }
    }

    var progress: Double {
        budget.amount > 0 ? min(Double(spent) / Double(budget.amount), 1.0) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(categoryName).font(.subheadline)
                Spacer()
                Text("\(formatCents(spent)) / \(formatCents(budget.amount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress > 0.8 ? .red : progress > 0.6 ? .orange : .green)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)

            if progress > 0.8 {
                Text("即将超支")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

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
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
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
