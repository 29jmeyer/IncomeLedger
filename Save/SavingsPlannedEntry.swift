import Foundation

struct SavingsPlannedEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var amount: Double

    init(id: UUID = UUID(), date: Date, amount: Double) {
        self.id = id
        self.date = date
        self.amount = amount
    }
}
