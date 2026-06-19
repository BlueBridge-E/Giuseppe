import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SoundManager.self) private var soundManager
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var viewModel = HomeViewModel()
    @FocusState private var isAmountFocused: Bool
    @State private var editingTransaction: Transaction?

    private let displayLimit = 10

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WealthCardView(
                        supportDays: viewModel.supportDays,
                        statusText: viewModel.statusText,
                        statusColor: viewModel.statusColor,
                        isLoading: viewModel.isLoading
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

                            ForEach(transactions.prefix(displayLimit)) { txn in
                                TransactionRow(transaction: txn, categories: categories)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingTransaction = txn }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            modelContext.delete(txn)
                                            viewModel.refreshWealth(accounts: accounts, transactions: transactions)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("记账")
            .overlay(alignment: .top) {
                if viewModel.showUndoToast {
                    HStack {
                        Text("已记账 \(viewModel.undoAmountText) 元")
                            .font(.subheadline)
                        Spacer()
                        Button("撤销") {
                            viewModel.undoLastTransaction()
                        }
                        .font(.subheadline.bold())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.showUndoToast)
            .onAppear {
                viewModel.setup(
                    modelContext: modelContext,
                    accounts: accounts,
                    transactions: transactions,
                    soundManager: soundManager
                )
                isAmountFocused = true
            }
            .onChange(of: transactions.count) {
                viewModel.refreshWealth(accounts: accounts, transactions: transactions)
            }
            .sheet(item: $editingTransaction) { txn in
                EditTransactionSheet(
                    transaction: txn,
                    categories: categories,
                    accounts: accounts
                ) {
                    viewModel.refreshWealth(accounts: accounts, transactions: transactions)
                }
            }
        }
    }
}

// MARK: - HomeViewModel

@Observable
final class HomeViewModel {
    var amountText = ""
    var selectedCategoryId: UUID?
    var supportDays: Double = 0
    var statusText = ""
    var statusColor: Color = .blue
    var isLoading = true
    var showUndoToast = false
    var undoAmountText = ""

    private var modelContext: ModelContext?
    private var lastTransaction: Transaction?
    private var lastBalanceAccount: Account?
    private var lastBalanceDelta: Int = 0
    private var accounts: [Account] = []
    private var transactions: [Transaction] = []
    private let wealthService = WealthSupportDayService()
    private weak var soundManager: SoundManager?

    func setup(
        modelContext: ModelContext,
        accounts: [Account],
        transactions: [Transaction],
        soundManager: SoundManager
    ) {
        self.modelContext = modelContext
        self.accounts = accounts
        self.transactions = transactions
        self.soundManager = soundManager
        refreshWealth(accounts: accounts, transactions: transactions)
    }

    func selectCategory(_ category: Category) {
        guard let context = modelContext,
              let yuan = Double(amountText), yuan > 0 else { return }

        let cents = yuanToCents(yuan)

        let fetchDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let defaultAccount = (try? context.fetch(fetchDescriptor))?.first else { return }

        let transaction = Transaction(
            amount: cents,
            type: category.type,
            categoryId: category.id,
            accountId: defaultAccount.id
        )
        context.insert(transaction)

        switch category.type {
        case .expense:
            defaultAccount.balance -= cents
            soundManager?.playExpenseSound()
        case .income:
            defaultAccount.balance += cents
            soundManager?.playIncomeSound()
        case .transfer, .refund:
            // 转账/退款暂未实现，跳过余额变动
            break
        }

        // 存储撤销信息
        lastTransaction = transaction
        lastBalanceAccount = defaultAccount
        lastBalanceDelta = category.type.isExpense ? -cents : cents
        showUndoToast = true
        undoAmountText = "\(category.type.isExpense ? "-" : "+")\(formatCents(cents))"

        selectedCategoryId = nil
        amountText = ""
        refreshWealth(accounts: accounts, transactions: transactions)

        // 2 秒后自动隐藏撤销
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showUndoToast = false
        }
    }

    func undoLastTransaction() {
        guard let context = modelContext,
              let txn = lastTransaction,
              let account = lastBalanceAccount else { return }

        // 回滚余额
        if txn.type.isExpense {
            account.balance += txn.amount
        } else {
            account.balance -= txn.amount
        }

        context.delete(txn)
        lastTransaction = nil
        lastBalanceAccount = nil
        lastBalanceDelta = 0
        showUndoToast = false

        refreshWealth(accounts: accounts, transactions: transactions)
    }

    func refreshWealth(accounts: [Account], transactions: [Transaction]) {
        self.accounts = accounts
        self.transactions = transactions
        supportDays = wealthService.calculateSupportDays(
            accounts: accounts,
            transactions: transactions
        )
        let status = wealthService.statusLabel(for: supportDays)
        statusText = status.text
        statusColor = wealthService.statusColor(for: supportDays)
        isLoading = false
    }
}

// MARK: - TransactionRow

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
            Text(transaction.type.isExpense ? "-\(formatCents(transaction.amount))" : "+\(formatCents(transaction.amount))")
                .font(.subheadline)
                .foregroundStyle(transaction.type.isExpense ? .red : .green)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category?.name ?? "") \(transaction.type.isExpense ? "支出" : "收入") \(formatCents(transaction.amount))元")
    }
}

// MARK: - EditTransactionSheet

struct EditTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var transaction: Transaction
    let categories: [Category]
    let accounts: [Account]
    let onSave: () -> Void

    @State private var amountText: String
    @State private var selectedType: TransactionType
    @State private var selectedCategoryId: UUID
    @State private var selectedAccountId: UUID
    @State private var noteText: String
    @State private var date: Date

    // 原始值用于余额回滚
    private let originalAmount: Int
    private let originalType: TransactionType
    private let originalAccountId: UUID

    init(transaction: Transaction, categories: [Category], accounts: [Account], onSave: @escaping () -> Void) {
        self.transaction = transaction
        self.categories = categories
        self.accounts = accounts
        self.onSave = onSave
        _amountText = State(initialValue: formatCents(transaction.amount))
        _selectedType = State(initialValue: transaction.type)
        _selectedCategoryId = State(initialValue: transaction.categoryId)
        _selectedAccountId = State(initialValue: transaction.accountId)
        _noteText = State(initialValue: transaction.note ?? "")
        _date = State(initialValue: transaction.date)
        originalAmount = transaction.amount
        originalType = transaction.type
        originalAccountId = transaction.accountId
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("金额", text: $amountText)
                    .keyboardType(.decimalPad)

                Picker("类型", selection: $selectedType) {
                    Text("支出").tag(TransactionType.expense)
                    Text("收入").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)

                Picker("分类", selection: $selectedCategoryId) {
                    ForEach(categories.filter { $0.type == selectedType }, id: \.id) { cat in
                        Text(cat.name).tag(cat.id)
                    }
                }

                Picker("账户", selection: $selectedAccountId) {
                    ForEach(accounts, id: \.id) { acc in
                        Text(acc.name).tag(acc.id)
                    }
                }

                DatePicker("日期", selection: $date, displayedComponents: .date)

                TextField("备注", text: $noteText)
            }
            .navigationTitle("编辑账单")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("更新") { saveChanges() }
                }
            }
        }
    }

    private func saveChanges() {
        guard let newAmount = Double(amountText).map(yuanToCents), newAmount > 0 else { return }

        // 先找到新旧账户，合并验证确保原子性
        let oldAccount = accounts.first(where: { $0.id == originalAccountId })
        let newAccount = accounts.first(where: { $0.id == selectedAccountId })

        // 回滚旧余额
        if let oldAcc = oldAccount {
            if originalType.isExpense {
                oldAcc.balance += originalAmount
            } else {
                oldAcc.balance -= originalAmount
            }
        }

        // 更新交易字段
        transaction.amount = newAmount
        transaction.type = selectedType
        transaction.categoryId = selectedCategoryId
        transaction.accountId = selectedAccountId
        transaction.date = date
        transaction.note = noteText.isEmpty ? nil : noteText
        transaction.updatedAt = Date()

        // 应用新余额
        if let newAcc = newAccount {
            if selectedType.isExpense {
                newAcc.balance -= newAmount
            } else {
                newAcc.balance += newAmount
            }
        }

        onSave()
        dismiss()
    }
}
