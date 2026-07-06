import WidgetKit
import SwiftUI

/// Reads the "plants needing care today" summary that the Flutter app
/// pushes into the shared App Group UserDefaults (see
/// lib/services/home_widget_service.dart) whenever care status changes.
private let appGroupId = "group.com.austinphillips.thicket"
private let countKey = "widget_plant_count"
private let plantsKey = "widget_plants_json"

struct PlantCareItem: Identifiable {
    let id = UUID()
    let name: String
    let status: String
}

struct PlantCareEntry: TimelineEntry {
    let date: Date
    let count: Int
    let plants: [PlantCareItem]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PlantCareEntry {
        PlantCareEntry(date: Date(), count: 2, plants: [
            PlantCareItem(name: "Monstera", status: "Water today"),
            PlantCareItem(name: "Pothos", status: "Overdue by 1 day"),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (PlantCareEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlantCareEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> PlantCareEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let count = defaults?.integer(forKey: countKey) ?? 0

        var plants: [PlantCareItem] = []
        if let json = defaults?.string(forKey: plantsKey),
           let data = json.data(using: .utf8),
           let decoded = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
            plants = decoded.map { PlantCareItem(name: $0["name"] ?? "", status: $0["status"] ?? "") }
        }
        return PlantCareEntry(date: Date(), count: count, plants: plants)
    }
}

struct ThicketWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.count == 0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("All caught up!")
                    .font(.headline)
            } else {
                Text("\(entry.count) plant\(entry.count == 1 ? "" : "s") need attention")
                    .font(.headline)
                    .lineLimit(2)
                ForEach(entry.plants.prefix(3)) { plant in
                    Text("\(plant.name): \(plant.status)")
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ThicketWidget: Widget {
    let kind: String = "ThicketWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ThicketWidgetView(entry: entry)
        }
        .configurationDisplayName("Plant Care")
        .description("See which plants need water or fertilizer today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct ThicketWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThicketWidget()
    }
}
