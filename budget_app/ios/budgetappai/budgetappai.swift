import WidgetKit
import SwiftUI

struct ProgressEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let item: ProgressItem?
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            item: ProgressItem(
                kind: "goal",
                id: "placeholder",
                name: "My Goal",
                icon: "🎯",
                progress: 45,
                subtitle: "$450 / $1,000"
            )
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> ProgressEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<ProgressEntry> {
        let entry = entry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func entry(for configuration: ConfigurationAppIntent) -> ProgressEntry {
        let item: ProgressItem?
        if let entity = configuration.item {
            item = WidgetDataLoader.findItem(kind: entity.kind, id: entity.itemId)
        } else {
            item = nil
        }

        return ProgressEntry(
            date: Date(),
            configuration: configuration,
            item: item
        )
    }
}

struct budgetappaiEntryView: View {
    var entry: Provider.Entry

    private var accent: Color {
        entry.item?.accentIsLoan == true
            ? Color(red: 0.96, green: 0.62, blue: 0.04)
            : Color(red: 0.39, green: 0.40, blue: 0.95)
    }

    var body: some View {
        if let item = entry.item {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.icon)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.kind == "loan" ? "LOAN" : "GOAL")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(accent)
                        Text(item.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("\(item.progress)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(accent)
                }

                ProgressView(value: Double(item.progress), total: 100)
                    .tint(accent)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("📊")
                    .font(.title2)
                Text("Choose a goal or loan")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Long-press widget → Edit Widget → pick Track")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
    }
}

struct budgetappai: Widget {
    let kind: String = "budgetappai"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            budgetappaiEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Goal / Loan Progress")
        .description("Shows progress for a specific savings goal or loan.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    budgetappai()
} timeline: {
    ProgressEntry(
        date: .now,
        configuration: .sampleGoal,
        item: ProgressItem(
            kind: "goal",
            id: "sample",
            name: "Vacation",
            icon: "✈️",
            progress: 62,
            subtitle: "$620 / $1,000"
        )
    )
}
