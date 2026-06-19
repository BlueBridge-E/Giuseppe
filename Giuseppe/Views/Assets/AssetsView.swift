import SwiftUI
import SwiftData

struct AssetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @State private var showingAddSheet = false
    @State private var editingAccount: Account?
    @State private var accountToDelete: Account?
    @State private var showingDeleteConfirmation = false

    /// 总资产：计入所有 includeInTotalAsset 的账户（displayBalance 自动处理信用卡负值）
    var totalAsset: Int {
        accounts
            .filter(\.includeInTotalAsset)
            .reduce(0) { $0 + $1.displayBalance }
    }

    /// 总负债：信用卡余额（正数表示负债金额）
    var totalLiability: Int {
        accounts
            .filter(\.isCredit)
            .reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("总览") {
                    HStack {
                        Text("总资产")
                        Spacer()
                        Text("¥\(formatCents(totalAsset))")
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Text("总负债")
                        Spacer()
                        Text("¥\(formatCents(totalLiability))")
                            .foregroundStyle(.red)
                    }
                    HStack {
                        Text("净资产")
                        Spacer()
                        Text("¥\(formatCents(totalAsset - totalLiability))")
                            .fontWeight(.bold)
                    }
                }

                Section("账户") {
                    ForEach(accounts) { account in
                        accountRow(account)
                    }
                }
            }
            .navigationTitle("资产")
            .toolbar {
                Button { showingAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAccountSheet { name, type, balance in
                    modelContext.insert(Account(name: name, type: type, balance: balance, sortOrder: accounts.count))
                }
            }
            .sheet(item: $editingAccount) { account in
                EditAccountSheet(account: account)
            }
            .confirmationDialog("确认删除", isPresented: $showingDeleteConfirmation, presenting: accountToDelete) { account in
                Button("删除", role: .destructive) {
                    modelContext.delete(account)
                }
                Button("取消", role: .cancel) { }
            } message: { account in
                Text("确定要删除「\(account.name)」吗？该账户下的交易将保留但失去关联。")
            }
        }
    }

    @ViewBuilder
    private func accountRow(_ account: Account) -> some View {
        HStack {
            Image(systemName: accountIcon(account.type))
                .foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.subheadline)
                Text(account.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("¥\(formatCents(account.displayBalance))")
                .foregroundStyle(account.displayBalance >= 0 ? .green : .red)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name)，\(account.type.displayName)，余额\(formatCents(account.displayBalance))元")
        .accessibilityHint("双击编辑账户")
        .onTapGesture { editingAccount = account }
        .swipeActions(edge: .leading) {
            Button { editingAccount = account } label: {
                Label("编辑", systemImage: "pencil")
            }.tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                accountToDelete = account
                showingDeleteConfirmation = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func accountIcon(_ type: AccountType) -> String {
        switch type {
        case .cash:        "banknote"
        case .bank:        "building.columns"
        case .credit:      "creditcard"
        case .storedValue: "wallet.pass"
        case .investment:  "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - 新增账户 Sheet（含初始余额）

struct AddAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, AccountType, Int) -> Void

    @State private var name = ""
    @State private var selectedType: AccountType = .bank
    @State private var initialBalanceText = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("账户名称", text: $name)
                Picker("类型", selection: $selectedType) {
                    ForEach(AccountType.allCases, id: \.rawValue) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                TextField("初始余额", text: $initialBalanceText)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("新增账户")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let defaultName = name.isEmpty ? selectedType.displayName : name
                        let balance = yuanToCents(Double(initialBalanceText) ?? 0)
                        onSave(defaultName, selectedType, balance)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 编辑账户 Sheet

struct EditAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    let account: Account

    @State private var name: String
    @State private var selectedType: AccountType
    @State private var balanceText: String

    init(account: Account) {
        self.account = account
        _name = State(initialValue: account.name)
        _selectedType = State(initialValue: account.type)
        _balanceText = State(initialValue: formatCents(account.displayBalance))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("账户名称", text: $name)
                Picker("类型", selection: $selectedType) {
                    ForEach(AccountType.allCases, id: \.rawValue) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                HStack {
                    Text(selectedType.isCredit ? "欠款金额" : "当前余额")
                    Spacer()
                    TextField(selectedType.isCredit ? "欠款" : "余额", text: $balanceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            .navigationTitle("编辑账户")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("更新") {
                        account.name = name
                        account.type = selectedType
                        if let newDisplayBalance = Double(balanceText) {
                            let cents = yuanToCents(newDisplayBalance)
                            // 信用卡 balance 为正数(欠款)，displayBalance 为负数 → 取反
                            account.balance = selectedType.isCredit ? -(cents) : cents
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
