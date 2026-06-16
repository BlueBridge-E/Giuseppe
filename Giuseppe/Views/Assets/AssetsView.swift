import SwiftUI
import SwiftData

struct AssetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @State private var showingAddSheet = false

    var totalAsset: Int {
        accounts.filter(\.includeInTotalAsset).reduce(0) { $0 + $1.displayBalance }
    }

    var totalLiability: Int {
        accounts.filter { $0.type == "credit" }.reduce(0) { $0 + $1.balance }
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
                        HStack {
                            Image(systemName: accountIcon(account.type))
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading) {
                                Text(account.name)
                                    .font(.subheadline)
                                Text(accountTypeName(account.type))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("¥\(formatCents(account.displayBalance))")
                                .foregroundStyle(account.displayBalance >= 0 ? .green : .red)
                        }
                    }
                    .onDelete(perform: deleteAccounts)
                }
            }
            .navigationTitle("资产")
            .toolbar {
                Button { showingAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAccountSheet { name, type in
                    modelContext.insert(Account(name: name, type: type, sortOrder: accounts.count))
                }
            }
        }
    }

    private func deleteAccounts(_ offsets: IndexSet) {
        for i in offsets { modelContext.delete(accounts[i]) }
    }

    private func accountIcon(_ type: String) -> String {
        switch type {
        case "cash":         "banknote"
        case "bank":         "building.columns"
        case "credit":       "creditcard"
        case "storedValue":  "wallet.pass"
        case "investment":   "chart.line.uptrend.xyaxis"
        default:             "questionmark.circle"
        }
    }

    private func accountTypeName(_ type: String) -> String {
        switch type {
        case "cash": "现金"
        case "bank": "银行卡"
        case "credit": "信用卡"
        case "storedValue": "储值卡"
        case "investment": "投资账户"
        default: type
        }
    }
}

struct AddAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String) -> Void

    @State private var name = ""
    @State private var selectedType = "bank"

    let types = ["cash", "bank", "credit", "storedValue", "investment"]
    let typeNames = ["现金", "银行卡", "信用卡", "储值卡", "投资账户"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("账户名称", text: $name)
                Picker("类型", selection: $selectedType) {
                    ForEach(Array(zip(types, typeNames)), id: \.0) { (value, label) in
                        Text(label).tag(value)
                    }
                }
            }
            .navigationTitle("新增账户")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let defaultName = typeNames[types.firstIndex(of: selectedType)!]
                        onSave(name.isEmpty ? defaultName : name, selectedType)
                        dismiss()
                    }
                }
            }
        }
    }
}
