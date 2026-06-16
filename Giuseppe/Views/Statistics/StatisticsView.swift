import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @State private var selectedPeriod: Period = .month

    enum Period: String, CaseIterable {
        case week = "周"
        case month = "月"
        case year = "年"
    }

    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch selectedPeriod {
        case .week:  startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month: startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:  startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        return transactions.filter { $0.date >= startDate && $0.type == "expense" }
    }

    var pieData: [(name: String, amount: Int, color: Color)] {
        var grouped: [UUID: Int] = [:]
        for t in filteredTransactions {
            grouped[t.categoryId, default: 0] += t.amount
        }
        return grouped.compactMap { (catId, amt) in
            guard let cat = categories.first(where: { $0.id == catId }) else { return nil }
            return (cat.name, amt, Color(hex: cat.color))
        }.sorted { $0.amount > $1.amount }
    }

    var totalExpense: Int {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Picker("时间", selection: $selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if !pieData.isEmpty {
                    PieChartView(data: pieData)
                        .padding(.horizontal)

                    ForEach(pieData, id: \.name) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.name)
                                .font(.caption)
                            Spacer()
                            Text("¥\(formatCents(item.amount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(Double(item.amount) / Double(max(totalExpense, 1)) * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    let dailyData = dailyTrend()
                    if !dailyData.isEmpty {
                        LineChartView(data: dailyData, color: .blue)
                            .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "暂无数据",
                        systemImage: "chart.bar",
                        description: Text("记一笔支出来查看统计")
                    )
                }
            }
            .navigationTitle("统计")
        }
    }

    private func dailyTrend() -> [(date: Date, amount: Int)] {
        let calendar = Calendar.current
        var result: [(Date, Int)] = []
        for day in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
            let total = transactions
                .filter { $0.date >= dayStart && $0.date < dayEnd && $0.type == "expense" }
                .reduce(0) { $0 + $1.amount }
            result.append((date, total))
        }
        return result.reversed()
    }
}
