import SwiftUI
import Charts

struct PieChartView: View {
    let data: [(name: String, amount: Int, color: Color)]

    var body: some View {
        Chart(data, id: \.name) { item in
            SectorMark(
                angle: .value("金额", item.amount),
                innerRadius: .ratio(0.6),
                angularInset: 1
            )
            .foregroundStyle(item.color)
        }
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("分类占比饼图")
        .accessibilityValue(data.map { "\($0.name) \(formatCents($0.amount))元" }.joined(separator: "，"))
    }
}
