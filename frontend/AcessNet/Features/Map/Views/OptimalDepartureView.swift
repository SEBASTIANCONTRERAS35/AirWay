//
//  OptimalDepartureView.swift
//  AcessNet
//
//  Vista "Mejor momento para salir" (Fase 7).
//  Muestra un chart con 12 ventanas horarias + detalle seleccionable.
//

import SwiftUI
import Charts
import CoreLocation
import os

struct OptimalDepartureView: View {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let vehicle: VehicleProfile
    let userProfile: [String: Any]?

    @State private var response: OptimalDepartureResponse?
    @State private var selectedIdx: Int = 0
    @State private var loading = true
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if loading {
                        ProgressView("Analizando 6 horas…")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else if let err = errorMsg {
                        errorView(err)
                    } else if let r = response {
                        content(r)
                    }
                }
                .padding()
            }
            .navigationTitle("Mejor momento")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
        }
    }

    @ViewBuilder
    private func content(_ r: OptimalDepartureResponse) -> some View {
        if let best = r.best {
            hero(best: best, savings: r.savingsIfBest, recommendation: r.recommendation)
        }

        chart(windows: r.windows)

        if r.windows.indices.contains(selectedIdx) {
            detail(window: r.windows[selectedIdx])
        }

        rankingList(windows: r.windows)
    }

    // MARK: - Hero

    private func hero(best: DepartureWindow, savings: DepartureSavings?, recommendation: String?) -> some View {
        VStack(spacing: 10) {
            Text("Mejor momento para salir")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text(best.departTimeLabel)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.green)

            HStack(spacing: 18) {
                heroStat(icon: "clock.fill", value: "\(Int(best.durationMin)) min", color: .blue)
                heroStat(icon: "pesosign.circle.fill", value: "$\(Int(best.pesosCost))", color: .green)
                heroStat(icon: "leaf.fill", value: "AQI \(best.aqiAvg)", color: aqiColor(best.aqiAvg))
            }

            if let savings = savings, savings.pesos + savings.minutes + Double(savings.exposurePct) > 0.1 {
                VStack(spacing: 4) {
                    if savings.pesos > 1 {
                        Text("Ahorrarás $\(Int(savings.pesos)) MXN")
                            .foregroundColor(.green)
                    }
                    if savings.exposurePct > 5 {
                        Text("Reducirás \(savings.exposurePct)% exposición al aire contaminado")
                            .foregroundColor(.blue)
                    }
                }
                .font(.caption.bold())
            }

            if let txt = recommendation {
                Text(txt)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [.green.opacity(0.08), .blue.opacity(0.05)],
                                    startPoint: .top, endPoint: .bottom))
        )
    }

    private func heroStat(icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).foregroundColor(color)
            Text(value)
                .font(.subheadline.bold())
                .monospacedDigit()
        }
    }

    // MARK: - Chart

    private func chart(windows: [DepartureWindow]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comparativa")
                .font(.headline)

            Chart(windows) { win in
                BarMark(
                    x: .value("Hora", win.departTimeLabel),
                    y: .value("Score", win.score)
                )
                .foregroundStyle(scoreColor(win.score))
                .annotation(position: .top, alignment: .center) {
                    if win.rank == 1 {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                    }
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100])
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .foregroundStyle(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            let relative = location.x - geo.frame(in: .local).origin.x
                            let barWidth = geo.size.width / CGFloat(max(windows.count, 1))
                            let idx = Int(relative / barWidth)
                            if windows.indices.contains(idx) {
                                selectedIdx = idx
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(12)
    }

    // MARK: - Detail

    private func detail(window: DepartureWindow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Salir a las \(window.departTimeLabel)")
                    .font(.headline)
                Spacer()
                Text("Rank #\(window.rank)")
                    .font(.caption.bold())
                    .padding(6)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }

            HStack(spacing: 18) {
                detailItem("Duración", "\(Int(window.durationMin)) min")
                detailItem("Costo", "$\(Int(window.pesosCost))")
                detailItem("Litros", String(format: "%.2f", window.liters))
            }
            HStack(spacing: 18) {
                detailItem("AQI", "\(window.aqiAvg)")
                detailItem("Tráfico", String(format: "×%.2f", window.trafficFactor))
                detailItem("CO₂", String(format: "%.1f kg", window.co2Kg))
            }

            if let sub = window.subScores {
                Divider().padding(.vertical, 4)
                Text("Desglose del score")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                subScoreBar("Tiempo", sub.time, color: .blue)
                subScoreBar("Costo", sub.cost, color: .green)
                subScoreBar("AQI", sub.aqi, color: .orange)
                subScoreBar("Exposición", sub.exposure, color: .pink)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(12)
    }

    private func detailItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.subheadline.bold()).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func subScoreBar(_ label: String, _ value: Double, color: Color) -> some View {
        HStack {
            Text(label).font(.caption2).frame(width: 72, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value / 100))
                }
            }
            .frame(height: 6)
            Text("\(Int(value))")
                .font(.caption2.monospacedDigit())
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func rankingList(windows: [DepartureWindow]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Todas las ventanas")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            ForEach(windows.sorted(by: { $0.departDate < $1.departDate })) { win in
                HStack {
                    Text(win.departTimeLabel)
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 52, alignment: .leading)
                    Text("\(Int(win.durationMin)) min")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 52, alignment: .leading)
                    Text("$\(Int(win.pesosCost))")
                        .font(.caption.monospacedDigit())
                        .frame(width: 52, alignment: .leading)
                    Text("AQI \(win.aqiAvg)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(aqiColor(win.aqiAvg))
                    Spacer()
                    scorePill(win.score)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.04))
        .cornerRadius(12)
    }

    private func scorePill(_ score: Double) -> some View {
        Text("\(Int(score))")
            .font(.caption.bold())
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(scoreColor(score).opacity(0.2))
            .foregroundColor(scoreColor(score))
            .cornerRadius(6)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private func aqiColor(_ aqi: Int) -> Color {
        switch aqi {
        case ..<51: return .green
        case 51..<101: return .yellow
        case 101..<151: return .orange
        case 151..<201: return .red
        case 201..<301: return .purple
        default: return .brown
        }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("No pudimos analizar").font(.headline)
            Text(msg).font(.caption).foregroundColor(.secondary)
            Button("Reintentar") { Task { await load() } }
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 80)
    }

    // MARK: - Load

    private func load() async {
        loading = true
        errorMsg = nil
        AirWayLogger.ui.info(
            "OptimalDepartureView loading vehicle=\(self.vehicle.fullDisplayName, privacy: .public) profile=\(self.userProfile != nil, privacy: .public)"
        )
        defer { loading = false }

        let now = Date()
        let earliest = now
        let latest = now.addingTimeInterval(6 * 3600)  // 6h window

        do {
            response = try await DepartureOptimizerAPI.shared.suggest(
                origin: origin,
                destination: destination,
                vehicle: vehicle,
                earliest: earliest,
                latest: latest,
                stepMin: 30,
                userProfile: userProfile
            )
            AirWayLogger.ui.info(
                "OptimalDepartureView loaded \(self.response?.windows.count ?? 0) windows, best=\(self.response?.best?.departTimeLabel ?? "?", privacy: .public)"
            )
            // Auto-seleccionar la ventana "best"
            if let best = response?.best,
               let idx = response?.windows.firstIndex(where: { $0.id == best.id }) {
                selectedIdx = idx
            }
        } catch {
            errorMsg = error.localizedDescription
            AirWayLogger.ui.error("OptimalDepartureView failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
