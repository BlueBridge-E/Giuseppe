import SwiftUI

struct WealthCardView: View {
    let supportDays: Double
    let statusText: String
    var statusColor: Color = .blue
    var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            } else {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(statusColor, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("财富支撑日")
        .accessibilityValue("可支撑 \(String(format: "%.1f", supportDays)) 天，\(statusText)")
    }
}
