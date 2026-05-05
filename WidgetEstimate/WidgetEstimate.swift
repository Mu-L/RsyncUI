import Foundation
import RsyncUIDeepLinks
import SwiftUI
import WidgetKit

@MainActor
struct RsyncUIEstimateProvider: @preconcurrency TimelineProvider {
    func placeholder(in _: Context) -> RsyncUIWidgetEstimateEntry {
        RsyncUIWidgetEstimateEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (RsyncUIWidgetEstimateEntry) -> Void) {
        Task { @MainActor in
            let entry = await makeEntry(for: Date())
            completion(entry)
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentDate = Date()
        if let entryDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate) {
            Task { @MainActor in
                let entry = await makeEntry(for: entryDate)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
            }
        }
    }

    private func makeEntry(for date: Date) async -> RsyncUIWidgetEstimateEntry {
        guard let urlString = await readconfiguration(),
              urlString.isEmpty == false,
              let url = URL(string: urlString)
        else {
            return RsyncUIWidgetEstimateEntry(date: date)
        }

        do {
            let queryelements = try RsyncUIDeepLinks().validateScheme(url)
            return RsyncUIWidgetEstimateEntry(
                date: date,
                urlstringestimate: url,
                profile: queryelements?.queryItems?.first?.value
            )
        } catch {
            return RsyncUIWidgetEstimateEntry(date: date, urlstringestimate: url)
        }
    }

    private func readconfiguration() async -> String? {
        let userconfigjson = "rsyncuiconfig.json"

        guard let path = documentscatalog else { return nil }

        let userconfigurationfileURL = URL(fileURLWithPath: path)
            .appendingPathComponent(userconfigjson)

        do {
            let importeddata = try await SharedJSONStorageReader.shared.decode(
                DecodeStringEstimate.self,
                from: userconfigurationfileURL
            )
            return importeddata.urlstringestimate
        } catch {
            return nil
        }
    }

    var documentscatalog: String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        return paths.firstObject as? String
    }
}

struct RsyncUIWidgetEstimateEntry: TimelineEntry {
    let date: Date
    var urlstringestimate: URL?
    var profile: String?
}

struct RsyncUIWidgetEstimateEntryView: View {
    var entry: RsyncUIEstimateProvider.Entry

    var body: some View {
        if let url = entry.urlstringestimate,
           let profile = entry.profile {
            VStack(alignment: .leading) {
                Text("Synchronize")
                    .font(.title2)
                Text("Profile: \(profile)")
                HStack {
                    Text(entry.date, style: .time)
                    Image(systemName: "bolt.shield.fill")
                        .foregroundStyle(Color(.yellow))
                        .widgetURL(url)
                }
            }
        } else {
            HStack {
                Text("Estimate: no URL set")
                HStack {
                    Text(entry.date, style: .time)
                    Image(systemName: "bolt.shield.fill")
                        .foregroundStyle(Color(.red))
                }
            }
        }
    }
}

struct WidgetEstimate: Widget {
    let kind: String = "WidgetEstimate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RsyncUIEstimateProvider()) { entry in
            RsyncUIWidgetEstimateEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Estimate")
        .description("Estimate & Synchronize your files.")
    }
}

struct DecodeStringEstimate: Codable {
    let urlstringestimate: String?

    enum CodingKeys: String, CodingKey {
        case urlstringestimate
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        urlstringestimate = try values.decodeIfPresent(String.self, forKey: .urlstringestimate)
    }
}
