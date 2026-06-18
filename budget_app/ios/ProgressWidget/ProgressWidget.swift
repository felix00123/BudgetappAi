import WidgetKit
import SwiftUI

private struct ProgressEntry: TimelineEntry {
    let date: Date
    let icon: String
    let name: String
    let typeLabel: String
    let progress: Int
    let subtitle: String
    let accent: Color
    let configured: Bool
}

private struct ProgressWidgetEntryView: View {
    var entry: ProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.typeLabel.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(entry.accent)
                    Text(entry.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(entry.progress)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(entry.accent)
            }

            ProgressView(value: Double(entry.progress), total: 100)
                .tint(entry.accent)

            if !entry.subtitle.isEmpty {
                Text(entry.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
    }
}

private struct ProgressWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(
            date: Date(),
            icon: "🎯",
            name: "My Goal",
            typeLabel: "Goal",
            progress: 45,
            subtitle: "$450 / $1,000",
            accent: Color(red: 0.39, green: 0.40, blue: 0.95),
            configured: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> ProgressEntry {
        let defaults = UserDefaults(suiteName: "group.com.budgetapp.budgetApp")
        let type = defaults?.string(forKey: "flutter.widget_selected_type")
        let itemId = defaults?.string(forKey: "flutter.widget_selected_id")

        guard let type, let itemId else {
            return ProgressEntry(
                date: Date(),
                icon: "📊",
                name: "Configure in app",
                typeLabel: "Progress",
                progress: 0,
                subtitle: "Goals or Loans → widget icon",
                accent: Color(red: 0.39, green: 0.40, blue: 0.95),
                configured: false
            )
        }

        let dataKey = type == "loan" ? "loans_widget_data" : "goals_widget_data"
        let raw = defaults?.string(forKey: "flutter.\(dataKey)") ?? "[]"
        guard
            let data = raw.data(using: .utf8),
            let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
            let item = array.first(where: { ($0["id"] as? String) == itemId }),
            let name = item["name"] as? String
        else {
            return ProgressEntry(
                date: Date(),
                icon: "⚠️",
                name: "Item not found",
                typeLabel: "Progress",
                progress: 0,
                subtitle: "Reconfigure in app",
                accent: Color.orange,
                configured: false
            )
        }

        let icon = item["icon"] as? String ?? (type == "loan" ? "🏦" : "🎯")
        let progress = min(max(item["progress"] as? Int ?? 0, 0), 100)
        let subtitle = item["subtitle"] as? String ?? ""
        let accent = type == "loan"
            ? Color(red: 0.96, green: 0.62, blue: 0.04)
            : Color(red: 0.39, green: 0.40, blue: 0.95)

        return ProgressEntry(
            date: Date(),
            icon: icon,
            name: name,
            typeLabel: type == "loan" ? "Loan" : "Goal",
            progress: progress,
            subtitle: subtitle,
            accent: accent,
            configured: true
        )
    }
}

@main
struct ProgressWidgetBundle: WidgetBundle {
    var body: some Widget {
        ProgressWidget()
    }
}

struct ProgressWidget: Widget {
    let kind: String = "ProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressWidgetProvider()) { entry in
            ProgressWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Goal / Loan Progress")
        .description("Shows progress for a goal or loan configured in the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
