import Foundation

struct ProgressItem {
    let kind: String
    let id: String
    let name: String
    let icon: String
    let progress: Int
    let subtitle: String

    var entityId: String { "\(kind):\(id)" }

    var accentIsLoan: Bool { kind == "loan" }
}

enum WidgetDataLoader {
    static let appGroupId = "group.com.budgetapp.budgetApp"
    private static let goalsKey = "goals_widget_data"
    private static let loansKey = "loans_widget_data"

    static func loadAllItems() -> [ProgressItem] {
        loadGoals() + loadLoans()
    }

    static func loadGoals() -> [ProgressItem] {
        parseItems(raw: readRaw(key: goalsKey), kind: "goal", defaultIcon: "🎯")
    }

    static func loadLoans() -> [ProgressItem] {
        parseItems(raw: readRaw(key: loansKey), kind: "loan", defaultIcon: "🏦")
    }

    static func findItem(kind: String, id: String) -> ProgressItem? {
        let items = kind == "loan" ? loadLoans() : loadGoals()
        return items.first { $0.id == id }
    }

    static func findItem(entityId: String) -> ProgressItem? {
        let parts = entityId.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return findItem(kind: parts[0], id: parts[1])
    }

    private static func readRaw(key: String) -> String {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return "[]" }
        if let value = defaults.string(forKey: key) { return value }
        if let value = defaults.string(forKey: "flutter.\(key)") { return value }
        return "[]"
    }

    private static func parseItems(raw: String, kind: String, defaultIcon: String) -> [ProgressItem] {
        guard
            let data = raw.data(using: .utf8),
            let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }

        return array.compactMap { dict in
            guard
                let id = dict["id"] as? String,
                let name = dict["name"] as? String
            else {
                return nil
            }

            let icon = dict["icon"] as? String ?? defaultIcon
            let progress = min(max(dict["progress"] as? Int ?? 0, 0), 100)
            let subtitle = dict["subtitle"] as? String ?? ""

            return ProgressItem(
                kind: kind,
                id: id,
                name: name,
                icon: icon,
                progress: progress,
                subtitle: subtitle
            )
        }
    }
}
