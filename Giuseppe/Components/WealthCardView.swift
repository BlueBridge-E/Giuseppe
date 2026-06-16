import SwiftUI

struct WealthCardView: View {
    let supportDays: Double
    let statusText: String

    var body: some View {
        VStack(spacing: 4) {
            Text("你的财富可支撑")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", supportDays))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("天")
                    .font(.body)
            }
            .foregroundStyle(.white)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.tint, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
