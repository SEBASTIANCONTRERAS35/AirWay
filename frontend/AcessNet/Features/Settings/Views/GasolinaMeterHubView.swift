//
//  GasolinaMeterHubView.swift
//  AcessNet
//
//  Centro de control de GasolinaMeter — menú que da acceso a todas las
//  vistas nuevas (Fases 1-8) para testing y demo.
//
//  Acceso: Settings → "GasolinaMeter" → GasolinaMeterHubView
//

import SwiftUI
import CoreLocation

struct GasolinaMeterHubView: View {
    @StateObject private var vehicleService = VehicleProfileService.shared
    @StateObject private var telemetry = DrivingTelemetryService.shared

    @State private var showingVehicleProfile = false
    @State private var showingVehicleScan = false
    @State private var showingTripRecorder = false
    @State private var showingOBD2 = false
    @State private var showingModeComparison = false
    @State private var showingOptimalDeparture = false
    @State private var showingStations = false
    @State private var showingBackendTest = false

    // Coordenadas demo CDMX (Zócalo → Polanco)
    private let demoOrigin = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
    private let demoDestination = CLLocationCoordinate2D(latitude: 19.4330, longitude: -99.1950)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    activeVehicleCard
                    phase1_2Section      // Perfil + Wallet
                    phase3Section        // Gasolineras
                    phase4Section        // Multimodal
                    phase5Section        // Gemini Vision
                    phase6Section        // Telemetría
                    phase7Section        // Mejor momento
                    phase8Section        // OBD-II
                    backendTestSection
                    logsSection
                }
                .padding()
            }
            .navigationTitle("GasolinaMeter")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingVehicleProfile) { VehicleProfileView() }
            .sheet(isPresented: $showingVehicleScan) { VehicleScanView() }
            .sheet(isPresented: $showingTripRecorder) {
                NavigationStack { TripRecorderView().navigationTitle("Viaje") }
            }
            .sheet(isPresented: $showingOBD2) { OBD2ConnectionView() }
            .sheet(isPresented: $showingModeComparison) {
                ModeComparisonSheet(
                    origin: demoOrigin,
                    destination: demoDestination,
                    vehicle: vehicleService.activeProfile
                )
            }
            .sheet(isPresented: $showingOptimalDeparture) {
                if let vehicle = vehicleService.activeProfile {
                    OptimalDepartureView(
                        origin: demoOrigin,
                        destination: demoDestination,
                        vehicle: vehicle,
                        userProfile: nil
                    )
                } else {
                    noVehicleHint
                }
            }
            .sheet(isPresented: $showingStations) {
                StationsNearbyTestView(origin: demoOrigin)
            }
            .sheet(isPresented: $showingBackendTest) {
                BackendTestView()
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "fuelpump.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(LinearGradient(
                    colors: [.green, .teal], startPoint: .top, endPoint: .bottom
                ))
            Text("GasolinaMeter")
                .font(.title2.bold())
            Text("Toca cada fase para probar. Logs visibles en Console.app con subsystem `mx.airway`.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.06))
        .cornerRadius(16)
    }

    // MARK: - Active Vehicle

    private var activeVehicleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VEHÍCULO ACTIVO")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .tracking(1)
            if let v = vehicleService.activeProfile {
                HStack {
                    Image(systemName: v.fuelType.systemIcon)
                        .font(.title2)
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text(v.displayName).font(.headline)
                        Text("\(String(format: "%.1f", v.conueeKmPerL)) km/L · Estilo: \(v.drivingStyleLabel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Sin vehículo activo").font(.headline)
                        Text("Configura uno en Fase 1 o Fase 5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Phase Sections

    private var phase1_2Section: some View {
        PhaseSection(
            number: "1 + 2",
            title: "Perfil de vehículo + Wallet-o-meter",
            icon: "car.fill",
            color: .blue
        ) {
            PhaseButton(
                icon: "car.side.fill",
                title: "Mis vehículos",
                subtitle: "Agrega/edita con catálogo CONUEE (49 autos)",
                action: { showingVehicleProfile = true }
            )
            PhaseButton(
                icon: "gauge.medium",
                title: "Probar Wallet-o-meter",
                subtitle: "Se ve automático en tarjeta de ruta al seleccionar destino",
                secondary: true,
                action: {}
            )
        }
    }

    private var phase3Section: some View {
        PhaseSection(
            number: "3",
            title: "Gasolinera más barata",
            icon: "fuelpump.fill",
            color: .orange
        ) {
            PhaseButton(
                icon: "mappin.circle.fill",
                title: "Gasolineras cerca (Zócalo)",
                subtitle: "Consulta live del backend /fuel/stations_near",
                action: { showingStations = true }
            )
        }
    }

    private var phase4Section: some View {
        PhaseSection(
            number: "4",
            title: "Auto vs Metro vs Uber vs Bici",
            icon: "arrow.triangle.branch",
            color: .purple
        ) {
            PhaseButton(
                icon: "chart.bar.horizontal.page.fill",
                title: "Comparar modos de transporte",
                subtitle: "Ruta demo: Zócalo → Polanco · 4 modos con insight Gemini",
                action: { showingModeComparison = true }
            )
        }
    }

    private var phase5Section: some View {
        PhaseSection(
            number: "5",
            title: "Gemini Vision identifica tu auto",
            icon: "camera.viewfinder",
            color: .pink
        ) {
            PhaseButton(
                icon: "camera.fill",
                title: "Escanear vehículo con cámara",
                subtitle: "Foto del tablero/placa/auto → Gemini identifica",
                action: { showingVehicleScan = true }
            )
        }
    }

    private var phase6Section: some View {
        PhaseSection(
            number: "6",
            title: "Telemetría sin hardware (CoreMotion)",
            icon: "waveform.path.ecg",
            color: .red
        ) {
            PhaseButton(
                icon: telemetry.isRecording ? "record.circle.fill" : "play.circle.fill",
                title: telemetry.isRecording ? "🔴 Viaje en curso" : "Registrar viaje",
                subtitle: telemetry.isRecording
                    ? "\(Int(telemetry.liveStats.speedKmh)) km/h · \(String(format: "%.1f", telemetry.liveStats.distanceKm)) km"
                    : "Usa acelerómetro + GPS · actualiza driving_style",
                action: { showingTripRecorder = true }
            )
        }
    }

    private var phase7Section: some View {
        PhaseSection(
            number: "7",
            title: "Mejor momento para salir",
            icon: "clock.badge.checkmark",
            color: .indigo
        ) {
            PhaseButton(
                icon: "chart.xyaxis.line",
                title: "Analizar 12 ventanas de 30 min",
                subtitle: "Multi-objetivo: tiempo + costo + AQI + exposición",
                action: { showingOptimalDeparture = true }
            )
        }
    }

    private var phase8Section: some View {
        PhaseSection(
            number: "8",
            title: "OBD-II Bluetooth (Premium)",
            icon: "antenna.radiowaves.left.and.right",
            color: .teal
        ) {
            PhaseButton(
                icon: "dot.radiowaves.left.and.right",
                title: "Conectar dongle ELM327",
                subtitle: "Requiere hardware OBD-II BLE ($30 Amazon)",
                action: { showingOBD2 = true }
            )
        }
    }

    private var backendTestSection: some View {
        PhaseSection(
            number: "BE",
            title: "Backend health check",
            icon: "server.rack",
            color: .gray
        ) {
            PhaseButton(
                icon: "network",
                title: "Probar endpoints HTTP",
                subtitle: "catalog · prices · estimate · stations",
                action: { showingBackendTest = true }
            )
        }
    }

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📋 VER LOGS")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .tracking(1)
            VStack(alignment: .leading, spacing: 6) {
                Label("Xcode: Cmd+Shift+Y (Debug Area)", systemImage: "chevron.left.forwardslash.chevron.right")
                Label("Console.app: filtrar `subsystem:mx.airway`", systemImage: "terminal.fill")
                Label {
                    Text("Terminal: ")
                        + Text("log stream --predicate 'subsystem == \"mx.airway\"' --level debug")
                        .font(.system(.caption, design: .monospaced))
                } icon: {
                    Image(systemName: "apple.terminal.fill")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }

    private var noVehicleHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Configura un vehículo primero").font(.headline)
            Text("Ve a Fase 1 → Mis vehículos")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Phase Section Container

private struct PhaseSection<Content: View>: View {
    let number: String
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.2))
                    Text(number)
                        .font(.caption.bold())
                        .foregroundColor(color)
                }
                .frame(width: 28, height: 28)
                Label(title, systemImage: icon)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
            }
            VStack(spacing: 8) {
                content()
            }
        }
        .padding(12)
        .background(color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Phase Button

private struct PhaseButton: View {
    let icon: String
    let title: String
    let subtitle: String
    var secondary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(secondary ? .secondary : .blue)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold())
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if !secondary {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(secondary)
    }
}

// MARK: - Stations Near Test View

struct StationsNearbyTestView: View {
    let origin: CLLocationCoordinate2D

    @State private var stations: [FuelStation] = []
    @State private var averagePrice: Double = 0
    @State private var loading = true
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            List {
                if loading {
                    ProgressView("Consultando backend...")
                } else if let err = errorMsg {
                    VStack(alignment: .leading) {
                        Text("Error").font(.headline).foregroundColor(.red)
                        Text(err).font(.caption)
                    }
                } else {
                    Section("Promedio Magna") {
                        Text("$\(String(format: "%.2f", averagePrice)) MXN/L")
                            .font(.title2.bold())
                    }
                    Section("Top 5 más baratas (1.5 km)") {
                        if stations.isEmpty {
                            Text("Sin estaciones en el radio").foregroundColor(.secondary)
                        }
                        ForEach(stations) { s in
                            HStack {
                                Image(systemName: "fuelpump.fill").foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(s.brand) · \(s.distanceKmFormatted)").font(.subheadline.bold())
                                    Text(s.address).font(.caption).foregroundColor(.secondary).lineLimit(1)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(s.priceFormatted).font(.subheadline.bold()).foregroundColor(.green)
                                    if let sv = s.savingsFormatted {
                                        Text(sv).font(.caption2).foregroundColor(.green)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .onTapGesture { s.openInMaps() }
                        }
                    }
                }
            }
            .navigationTitle("Gasolineras cercanas")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            let resp = try await FuelStationsAPI.shared.stationsNear(
                coordinate: origin, fuelType: .magna, radiusM: 1500, limit: 5
            )
            stations = resp.stations
            averagePrice = resp.averagePrice
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

// MARK: - Backend Test View

struct BackendTestView: View {
    @State private var catalogStatus = "—"
    @State private var pricesStatus = "—"
    @State private var estimateStatus = "—"
    @State private var stationsStatus = "—"
    @State private var running = false

    var body: some View {
        NavigationStack {
            List {
                Section("Endpoints Django") {
                    testRow("GET /fuel/catalog", status: catalogStatus)
                    testRow("GET /fuel/prices", status: pricesStatus)
                    testRow("POST /fuel/estimate", status: estimateStatus)
                    testRow("GET /fuel/stations_near", status: stationsStatus)
                }
                Section {
                    Button(running ? "Ejecutando..." : "Correr tests") {
                        Task { await runAllTests() }
                    }
                    .disabled(running)
                }
                Section("Base URL") {
                    Text(AppConfig.backendBaseURL.absoluteString)
                        .font(.caption.monospaced())
                }
            }
            .navigationTitle("Backend Health")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func testRow(_ title: String, status: String) -> some View {
        HStack {
            Text(title).font(.caption.monospaced())
            Spacer()
            Text(status)
                .font(.caption)
                .foregroundColor(statusColor(status))
        }
    }

    private func statusColor(_ s: String) -> Color {
        if s.contains("✓") { return .green }
        if s.contains("✗") { return .red }
        if s.contains("…") { return .blue }
        return .secondary
    }

    private func runAllTests() async {
        running = true
        defer { running = false }

        catalogStatus = "…"
        do {
            let resp = try await FuelAPIClient.shared.fetchCatalog()
            catalogStatus = "✓ \(resp.vehicles?.count ?? 0) autos"
        } catch {
            catalogStatus = "✗ \(error.localizedDescription)"
        }

        pricesStatus = "…"
        do {
            let prices = try await FuelAPIClient.shared.fetchPrices()
            pricesStatus = "✓ Magna $\(String(format: "%.2f", prices.magna))"
        } catch {
            pricesStatus = "✗ \(error.localizedDescription)"
        }

        stationsStatus = "…"
        do {
            let resp = try await FuelStationsAPI.shared.stationsNear(
                coordinate: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
                fuelType: .magna, radiusM: 3000, limit: 5
            )
            stationsStatus = "✓ \(resp.count) estaciones"
        } catch {
            stationsStatus = "✗ \(error.localizedDescription)"
        }

        estimateStatus = "…"
        // Necesita un polyline válido + vehículo — usamos un polyline dummy
        let dummyPoly = "_piF~poU_ulL~ztH" // CDMX short segment
        let vehicle = VehicleProfileService.shared.activeProfile ?? VehicleProfile.sample
        do {
            let est = try await FuelAPIClient.shared.estimate(
                polyline: dummyPoly,
                vehicle: vehicle,
                durationMin: 15,
                passengers: 1
            )
            estimateStatus = "✓ \(est.pesosFormatted)"
        } catch {
            estimateStatus = "✗ \(error.localizedDescription)"
        }
    }
}
