import SwiftUI

struct CategoryGrid: View {
    let categories: [Category]
    let selectedCategoryId: UUID?
    let onSelect: (Category) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories) { category in
                Button {
                    onSelect(category)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(
                                selectedCategoryId == category.id
                                    ? Color(hex: category.color)
                                    : Color(hex: category.color).opacity(0.15)
                            )
                            .foregroundStyle(
                                selectedCategoryId == category.id
                                    ? .white
                                    : Color(hex: category.color)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text(category.name)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
                .accessibilityLabel(category.name)
                .accessibilityHint(category.type.isExpense ? "支出分类，双击记账" : "收入分类，双击记账")
            }
        }
        .padding(.horizontal)
    }
}
