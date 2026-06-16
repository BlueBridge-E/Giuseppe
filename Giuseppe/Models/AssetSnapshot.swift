import Foundation
import SwiftData

@Model
final class AssetSnapshot {
    var id: UUID
    var date: Date
    var totalAsset: Int       // 分
    var totalLiability: Int   // 分

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        totalAsset: Int = 0,
        totalLiability: Int = 0
    ) {
        self.id = id
        self.date = date
        self.totalAsset = totalAsset
        self.totalLiability = totalLiability
    }

    var netAsset: Int { totalAsset - totalLiability }
}
