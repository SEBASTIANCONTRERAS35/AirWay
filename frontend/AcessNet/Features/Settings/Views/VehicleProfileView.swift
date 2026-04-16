//
//  VehicleProfileView.swift
//  AcessNet
//
//  Vista de gestión de perfiles de vehículo.
//  - Lista de perfiles guardados (multi-auto)
//  - Formulario para agregar/editar
//  - Búsqueda en catálogo CONUEE (autocomplete)
//

import SwiftUI

struct VehicleProfileView: View {
    @StateObject private var service = VehicleProfileService.shared
    @State private var showingEditor = false
    @State private var editingProfile: VehicleProfile?

    var body: some View {
        NavigationStack {
            List {
                if service.savedProfiles.isEmpty {
                    emptyState
                } else {
                    ForEach(service.savedProfiles) { profile in
                        ProfileRow(
                            profile: profile,
                            isActive: service.activeProfile?.id == profile.id,
                            onTap: { service.setActive(profile) },
                            onEdit: { editingProfile = profile; showingEditor = true }
                        )
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Mis vehículos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingProfile = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                VehicleEditorView(profile: editingProfile) { newProfile in
                    service.save(newProfile)
                    showingEditor = false
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.side.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("Agrega tu primer vehículo")
                .font(.title2.bold())
            Text("AirWay usará tu perfil para estimar consumo, costo en pesos y emisiones por cada ruta.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                editingProfile = nil
                showingEditor = true
            } label: {
                Label("Agregar vehículo", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            service.delete(service.savedProfiles[idx])
        }
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let profile: VehicleProfile
    let isActive: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: profile.fuelType.systemIcon)
                    .font(.title2)
                    .foregroundStyle(isActive ? .green : .secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(profile.displayName)
                            .font(.headline)
                        if isActive {
                            Text("Activo")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                    HStack(spacing: 6) {
                        Text(profile.fuelType.displayName)
                        Text("·")
                        Text(String(format: "%.1f km/L", profile.conueeKmPerL))
                        Text("·")
                        Text(profile.drivingStyleLabel)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Editor

struct VehicleEditorView: View {
    let profile: VehicleProfile?
    let onSave: (VehicleProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery: String = ""
    @State private var catalogResults: [ConueeVehicleEntry] = []
    @State private var isSearching = false

    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: Int = 2020
    @State private var fuelType: FuelType = .magna
    @State private var kmPerL: Double = 14.0
    @State private var engineCc: Int = 1600
    @State private var transmission: String = "manual"
    @State private var weightKg: Int = 1150
    @State private var nickname: String = ""
    @State private var odometerKm: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Buscar en catálogo CONUEE") {
                    TextField("Ej. Versa, Aveo, Prius...", text: $searchQuery)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onChange(of: searchQuery) { _, newValue in
                            Task { await searchCatalog(newValue) }
                        }

                    if isSearching {
                        ProgressView()
                    } else if !catalogResults.isEmpty {
                        ForEach(catalogResults) { entry in
                            Button {
                                apply(entry: entry)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(entry.make) \(entry.model) \(entry.year)")
                                            .font(.subheadline)
                                        Text("\(String(format: "%.1f", entry.conueeKmPerL)) km/L · \(entry.fuelType.displayName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Datos básicos") {
                    TextField("Marca", text: $make)
                    TextField("Modelo", text: $model)
                    Stepper("Año: \(year)", value: $year, in: 1990...2026)
                    Picker("Combustible", selection: $fuelType) {
                        ForEach(FuelType.allCases) { ft in
                            Text(ft.displayName).tag(ft)
                        }
                    }
                }

                Section("Rendimiento (CONUEE)") {
                    HStack {
                        Text("km/L")
                        Spacer()
                        TextField("14.0", value: $kmPerL, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Motor (opcional)") {
                    HStack {
                        Text("Cilindrada")
                        Spacer()
                        TextField("1600", value: $engineCc, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("cc")
                    }
                    Picker("Transmisión", selection: $transmission) {
                        Text("Manual").tag("manual")
                        Text("Automática").tag("automatic")
                        Text("CVT").tag("cvt")
                    }
                    HStack {
                        Text("Peso")
                        Spacer()
                        TextField("1150", value: $weightKg, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                    }
                }

                Section("Extra") {
                    TextField("Apodo (opcional)", text: $nickname)
                    TextField("Kilometraje actual", text: $odometerKm)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(profile == nil ? "Nuevo vehículo" : "Editar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: save)
                        .disabled(make.isEmpty || model.isEmpty)
                }
            }
            .onAppear(perform: loadInitial)
        }
    }

    private func loadInitial() {
        if let p = profile {
            make = p.make
            model = p.model
            year = p.year
            fuelType = p.fuelType
            kmPerL = p.conueeKmPerL
            engineCc = p.engineCc
            transmission = p.transmission
            weightKg = p.weightKg
            nickname = p.nickname ?? ""
            if let odo = p.odometerKm { odometerKm = String(odo) }
        }
    }

    private func apply(entry: ConueeVehicleEntry) {
        make = entry.make
        model = entry.model
        year = entry.year
        fuelType = entry.fuelType
        kmPerL = entry.conueeKmPerL
        engineCc = entry.engineCc
        transmission = entry.transmission
        weightKg = entry.weightKg
        catalogResults = []
        searchQuery = "\(entry.make) \(entry.model)"
    }

    private func searchCatalog(_ query: String) async {
        guard query.count >= 2 else {
            catalogResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }
        do {
            let resp = try await FuelAPIClient.shared.searchCatalog(query: query, limit: 10)
            catalogResults = resp.results
        } catch {
            catalogResults = []
        }
    }

    private func save() {
        let odoInt = Int(odometerKm)
        let newProfile = VehicleProfile(
            id: profile?.id ?? UUID(),
            make: make,
            model: model,
            year: year,
            fuelType: fuelType,
            conueeKmPerL: kmPerL,
            engineCc: engineCc,
            transmission: transmission,
            weightKg: weightKg,
            dragCoefficient: profile?.dragCoefficient ?? 0.33,
            drivingStyle: profile?.drivingStyle ?? 1.0,
            nickname: nickname.isEmpty ? nil : nickname,
            odometerKm: odoInt,
            createdAt: profile?.createdAt ?? Date(),
            updatedAt: Date()
        )
        onSave(newProfile)
        dismiss()
    }
}

#Preview {
    VehicleProfileView()
}
