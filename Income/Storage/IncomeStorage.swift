import Foundation

struct IncomeSnapshot: Codable {
    var jobs: [Job]
    var passiveIncomes: [PassiveIncome]
    var nonRecurringIncomes: [NonRecurringIncome]
    var jobOverrides: [JobPayPeriodOverride]
    var passiveOverrides: [PassiveIncomeOverride]
    var nonRecurringOverrides: [NonRecurringIncomeOverride]
}

enum IncomeStorage {
    private static let fileName = "income_data.json"

    private static var fileURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls.first!
        return docURL.appendingPathComponent(fileName)
    }

    static func load() -> IncomeSnapshot? {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(IncomeSnapshot.self, from: data)
        } catch {
            print("IncomeStorage load error: \(error)")
            return nil
        }
    }

    static func save(_ snapshot: IncomeSnapshot) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("IncomeStorage save error: \(error)")
        }
    }
}

