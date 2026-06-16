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
    }
}
