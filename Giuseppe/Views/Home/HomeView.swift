import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]

    @State private var viewModel = HomeViewModel()
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WealthCardView(
                        supportDays: viewModel.supportDays,
                        statusText: viewModel.statusText
                    )

                    AmountInputView(
                        amountText: $viewModel.amountText,
                        isFocused: $isAmountFocused
                    )

                    CategoryGrid(
                        categories: categories,
                        selectedCategoryId: viewModel.selectedCategoryId,
                        onSelect: { viewModel.selectCategory($0) }
                    )

                    if !transactions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("最近账单")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(transactions.sorted(by: { $0.date > $1.date }).prefix(10)) { txn in
                                TransactionRow(transaction: txn, categories: categories)
                            }
                        }
                    }
                }
            }
            .navigationTitle("记账")
            .onAppear {
                viewModel.setup(
                    modelContext: modelContext,
                    accounts: accounts,
                    transactions: transactions
                )
                isAmountFocused = true
            }
            .onChange(of: transactions.count) {
                viewModel.refreshWealth(accounts: accounts, transactions: transactions)
            }
        }
    }
}

@Observable
final class HomeViewModel {
    var amountText = ""
    var selectedCategoryId: UUID?
    var supportDays: Double = 0
    var statusText = ""

    private var modelContext: ModelContext?
    private let wealthService = WealthSupportDayService()

    func setup(modelContext: ModelContext, accounts: [Account], transactions: [Transaction]) {
        self.modelContext = modelContext
        refreshWealth(accounts: accounts, transactions: transactions)
    }

    func selectCategory(_ category: Category) {
        guard let context = modelContext,
              let yuan = Double(amountText), yuan > 0 else { return }

        let cents = yuanToCents(yuan)

        // Use first account as default
        let fetchDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        let defaultAccount = (try? context.fetch(fetchDescriptor))?.first

        let transaction = Transaction(
            amount: cents,
            type: category.type,
            categoryId: category.id,
            accountId: defaultAccount?.id ?? UUID()
        )
        context.insert(transaction)

        // Update account balance
        if let account = defaultAccount {
            if category.type == "expense" {
                account.balance -= cents
            } else {
                account.balance += cents
            }
        }

        selectedCategoryId = nil
        amountText = ""
    }

    func refreshWealth(accounts: [Account], transactions: [Transaction]) {
        supportDays = wealthService.calculateSupportDays(
            accounts: accounts,
            transactions: transactions
        )
        let status = wealthService.statusLabel(for: supportDays)
        statusText = status.text
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let categories: [Category]

    var category: Category? {
        categories.first { $0.id == transaction.categoryId }
    }

    var body: some View {
        HStack {
            Image(systemName: category?.icon ?? "questionmark.circle")
                .foregroundStyle(Color(hex: category?.color ?? "999999"))
            VStack(alignment: .leading) {
                Text(category?.name ?? "未知")
                    .font(.subheadline)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(transaction.type == "expense" ? "-\(formatCents(transaction.amount))" : "+\(formatCents(transaction.amount))")
                .font(.subheadline)
                .foregroundStyle(transaction.type == "expense" ? .red : .green)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
