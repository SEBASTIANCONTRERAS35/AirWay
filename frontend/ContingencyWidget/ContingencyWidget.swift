//
//  ContingencyWidget.swift
//  ContingencyWidget
//
//  Widget de Lock Screen + Home Screen que muestra la probabilidad
//  de contingencia ambiental en CDMX con color dinámico.
//
//  Setup requerido en Xcode:
//    1. File → New → Target → Widget Extension → "ContingencyWidget"
//    2. Arrastrar estos archivos al nuevo target
//    3. Marcar también Core/Models/ContingencyForecast.swift con membership
//       en este target para compartir los tipos Codable.
//

import WidgetKit
import SwiftUI

// MARK: - Entry

struct ContingencyEntry: TimelineEntry {
    let date: Date
    let probability: Double        // 0.0–1.0
    let horizonHours: Int
    let o3ExpectedPpb: Double?
    let isPlaceholder: Bool

    static let placeholder = ContingencyEntry(
        date: Date(),
        probability: 0.45,
        horizonHours: 24,
        o3ExpectedPpb: 128,
        isPlaceholder: true
    )
}

// MARK: - Timeline Provider

struct ContingencyProvider: TimelineProvider {

    private let baseURL = "https://airway-api.onrender.com/api/v1"

    func placeholder(in context: Context) -> ContingencyEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ContingencyEntry) -> Void) {
        Task {
            let entry = await fetchLatest() ?? .placeholder
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ContingencyEntry>) -> Void) {
        Task {
            let entry = await fetchLatest() ?? .placeholder
            // Update cada hora
            let nextUpdate = Date().addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    /// Fetch ligero al endpoint — solo toma prob de h+24.
    private func fetchLatest() async -> ContingencyEntry? {
        guard let url = URL(string: "\(baseURL)/contingency/forecast?lat=19.4326&lon=-99.1332")
        else { return nil }

        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }

            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let forecasts = json["forecasts"] as? [[String: Any]],
                let first = forecasts.first,
                let prob = first["prob_fase1_o3"] as? Double,
                let horizon = first["horizon_h"] as? Int
            else { return nil }

            let o3 = first["o3_expected_ppb"] as? Double

            return ContingencyEntry(
                date: Date(),
                probability: prob,
                horizonHours: horizon,
                o3ExpectedPpb: o3,
                isPlaceholder: false
            )
        } catch {
            print("[ContingencyWidget] fetch error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Helpers UI

private func color(for probability: Double) -> Color {
    switch probability {
    case 0..<0.3:   return .green
    case 0.3..<0.6: return .yellow
    case 0.6..<0.8: return .orange
    default:        return .red
    }
}

private func urgencyLabel(_ p: Double) -> String {
    switch p {
    case 0..<0.3:   return "Tranquilo"
    case 0.3..<0.6: return "Moderado"
    case 0.6..<0.8: return "Alerta"
    default:        return "Urgente"
    }
}

// MARK: - Views

struct ContingencyLockScreenView: View {
    let entry: ContingencyEntry

    var body: some View {
        HStack(spacing: 8) {
            Text("\(Int(round(entry.probability * 100)))%")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color(for: entry.probability))

            VStack(alignment: .leading, spacing: 0) {
                Text("Contingencia")
                    .font(.caption.weight(.medium))
                Text("en \(entry.horizonHours) h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct ContingencySmallView: View {
    let entry: ContingencyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "wind")
                    .foregroundColor(color(for: entry.probability))
                Text("Contingencia")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                Spacer()
            }

            Text("\(Int(round(entry.probability * 100)))%")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(color(for: entry.probability))

            Text("en \(entry.horizonHours) horas")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(urgencyLabel(entry.probability).uppercased())
                .font(.caption2.bold())
                .tracking(1)
                .foregroundColor(color(for: entry.probability))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget

struct ContingencyWidget: Widget {
    let kind: String = "ContingencyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ContingencyProvider()) { entry in
            ContingencyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ContingencyCast")
        .description("Probabilidad de contingencia ambiental con 24-72h de anticipación.")
        .supportedFamilies([
            .accessoryRectangular,
            .systemSmall,
        ])
    }
}

struct ContingencyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ContingencyEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            ContingencyLockScreenView(entry: entry)
        default:
            ContingencySmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    ContingencyWidget()
} timeline: {
    ContingencyEntry(date: .now, probability: 0.78, horizonHours: 24, o3ExpectedPpb: 158, isPlaceholder: false)
    ContingencyEntry(date: .now, probability: 0.32, horizonHours: 24, o3ExpectedPpb: 95, isPlaceholder: false)
}

#Preview(as: .systemSmall) {
    ContingencyWidget()
} timeline: {
    ContingencyEntry(date: .now, probability: 0.78, horizonHours: 24, o3ExpectedPpb: 158, isPlaceholder: false)
}
