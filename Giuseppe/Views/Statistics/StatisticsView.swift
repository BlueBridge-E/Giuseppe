import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @State private var selectedPeriod: Period = .month
    @State private var selectedType: TransactionType = .expense
    @State private var pieData: [(name: String, amount: Int, color: Color)] = []
    @State private var totalExpense: Int = 0
    @State private var dailyData: [(date: Date, amount: Int)] = []
    @State private var isLoading = true

    enum Period: String, CaseIterable {
        case week = "周"
        case month = "月"
        case year = "年"

        var dayCount: Int {
            switch self {
            case .week: 7
            case .month: 30
            case .year: 365
            }
        }
    }

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                Picker("类型", selection: $selectedType) {
                    Text("支出").tag(TransactionType.expense)
                    Text("收入").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                Picker("时间", selection: $selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

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

                    if !dailyData.isEmpty {
                        LineChartView(data: dailyData, color: .blue)
                            .padding()
                    }
                } else if !isLoading {
                    ContentUnavailableView(
                        "暂无数据",
                        systemImage: "chart.bar",
                        description: Text("记一笔支出来查看统计")
                    )
                }
            }
            .navigationTitle("统计")
            .animation(.easeInOut(duration: 0.3), value: selectedPeriod)
            .animation(.easeInOut(duration: 0.3), value: selectedType)
            .onAppear { computeAllStats() }
            .onChange(of: transactions.count) { computeAllStats() }
            .onChange(of: selectedPeriod) { computeAllStats() }
            .onChange(of: selectedType) { computeAllStats() }
        }
    }

    // MARK: - 统一计算（单次遍历 O(n)）

    /// 一次遍历完成：pieData、totalExpense、dailyTrend
    private func computeAllStats() {
        let now = Date()
        let periodDayCount = selectedPeriod.dayCount
        let startDate = calendar.date(byAdding: .day, value: -periodDayCount, to: now) ?? now

        // --- Pass 1: 过滤 + 分组 ---
        var grouped: [UUID: Int] = [:]
        var total = 0
        // 按天分组（用于折线图）
        var byDay: [Date: Int] = [:]

        for t in transactions {
            guard t.date >= startDate, t.type == selectedType else { continue }
            grouped[t.categoryId, default: 0] += t.amount
            total += t.amount
            let dayStart = calendar.startOfDay(for: t.date)
            byDay[dayStart, default: 0] += t.amount
        }

        // --- Pie Data ---
        pieData = grouped.compactMap { (catId, amt) in
            guard let cat = categories.first(where: { $0.id == catId }) else { return nil }
            return (cat.name, amt, Color(hex: cat.color))
        }.sorted { $0.amount > $1.amount }

        totalExpense = total

        // --- Daily Trend（O(days) 查询已分组字典） ---
        var trend: [(Date, Int)] = []
        for day in 0..<periodDayCount {
            let date = calendar.date(byAdding: .day, value: -day, to: now) ?? now
            let dayStart = calendar.startOfDay(for: date)
            trend.append((date, byDay[dayStart, default: 0]))
        }
        dailyData = trend.reversed()
        isLoading = false
    }
}
