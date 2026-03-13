import Foundation
import SwiftData

@Model
final class Portfolio {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade)
    var holdings: [Holding]
    var createdDate: Date

    var totalValue: Double {
        holdings.reduce(0) { $0 + $1.totalValue }
    }

    var totalCost: Double {
        holdings.reduce(0) { $0 + $1.totalCost }
    }

    var totalProfitLoss: Double {
        totalValue - totalCost
    }

    var totalProfitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (totalProfitLoss / totalCost) * 100
    }

    var holdingsByAssetType: [AssetType: [Holding]] {
        Dictionary(grouping: holdings) { $0.assetType }
    }

    var allocationByAssetType: [(assetType: AssetType, value: Double, percentage: Double)] {
        let total = totalValue
        guard total > 0 else { return [] }

        let grouped = holdingsByAssetType
        return grouped.map { assetType, holdings in
            let value = holdings.reduce(0) { $0 + $1.totalValue }
            let percentage = (value / total) * 100
            return (assetType: assetType, value: value, percentage: percentage)
        }
        .sorted { $0.value > $1.value }
    }

    init(
        id: UUID = UUID(),
        name: String = "My Portfolio",
        holdings: [Holding] = [],
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.holdings = holdings
        self.createdDate = createdDate
    }
}
