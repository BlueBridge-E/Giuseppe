import SwiftUI
import Charts

struct LineChartView: View {
    let data: [(date: Date, amount: Int)]
    let color: Color

    var body: some View {
        Chart(data, id: \.date) { point in
            LineMark(
                x: .value("日期", point.date, unit: .day),
                y: .value("金额", point.amount)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("日期", point.date, unit: .day),
                y: .value("金额", point.amount)
            )
            .foregroundStyle(color.opacity(0.1))
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("每日趋势折线图")
    }
}
