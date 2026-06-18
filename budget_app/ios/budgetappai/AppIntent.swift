import AppIntents
import WidgetKit

struct ProgressItemEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal or Loan")
    static var defaultQuery = ProgressItemQuery()

    let kind: String
    let itemId: String
    let name: String
    let icon: String

    var id: String { "\(kind):\(itemId)" }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(icon) \(name)")
    }

    init(item: ProgressItem) {
        kind = item.kind
        itemId = item.id
        name = item.name
        icon = item.icon
    }
}

struct ProgressItemQuery: EntityQuery {
    func entities(for identifiers: [ProgressItemEntity.ID]) async throws -> [ProgressItemEntity] {
        let all = WidgetDataLoader.loadAllItems().map(ProgressItemEntity.init)
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ProgressItemEntity] {
        WidgetDataLoader.loadAllItems().map(ProgressItemEntity.init)
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Goal / Loan Progress" }
    static var description: IntentDescription {
        "Choose which savings goal or loan this widget should track."
    }

    @Parameter(title: "Track")
    var item: ProgressItemEntity?
}

extension ConfigurationAppIntent {
    fileprivate static var sampleGoal: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.item = ProgressItemEntity(
            item: ProgressItem(
                kind: "goal",
                id: "sample",
                name: "My Goal",
                icon: "🎯",
                progress: 45,
                subtitle: "$450 / $1,000"
            )
        )
        return intent
    }
}
