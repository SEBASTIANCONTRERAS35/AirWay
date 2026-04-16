//
//  VehicleScanView.swift
//  AcessNet
//
//  Identifica tu vehículo con una foto (tablero, placa o vista exterior).
//  Usa Gemini Vision vía backend /api/v1/vehicle/identify_from_image.
//

import SwiftUI
import PhotosUI
import os

struct VehicleScanView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var result: VehicleVisionResult?
    @State private var loading = false
    @State private var errorMsg: String?
    @State private var showingCamera = false
    @State private var nickname: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroHeader

                    // Imagen capturada
                    if let img = capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(.purple.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        emptyPreview
                    }

                    // Loading / error / resultado
                    if loading {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Analizando con Gemini…")
                                .font(.callout)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.08))
                        .cornerRadius(12)
                    }

                    if let msg = errorMsg {
                        errorBanner(msg)
                    }

                    if let r = result {
                        resultCard(r)
                    }

                    buttons
                }
                .padding()
            }
            .navigationTitle("Escanear vehículo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .photosPicker(isPresented: .constant(false), selection: $pickerItem, matching: .images)
            .onChange(of: pickerItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        capturedImage = ui
                        await analyze(ui)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var heroHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
            Text("Apunta a tu tablero, placa o auto")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Gemini Vision identificará marca, modelo y rendimiento oficial CONUEE.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var emptyPreview: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.rear")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("Sin imagen")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(14)
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(msg).font(.callout).foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func resultCard(_ r: VehicleVisionResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Resultado", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundColor(.purple)
                Spacer()
                confidencePill(r.confidencePct)
            }

            if let make = r.make, let model = r.model {
                Label {
                    Text("\(make) \(model) \(r.yearEstimate.map(String.init) ?? "—")")
                        .font(.headline)
                } icon: {
                    Image(systemName: "car.fill")
                }
            }
            if let odo = r.odometerKm {
                Label("\(odo) km en el odómetro", systemImage: "gauge")
                    .font(.subheadline)
            }
            if let plate = r.plateNumber {
                Label(plate, systemImage: "signpost.right.fill")
                    .font(.subheadline)
                    .privacySensitive()
            }
            if let holo = r.holograma {
                Label("Holograma \(holo)", systemImage: "seal.fill")
                    .font(.subheadline)
                    .foregroundColor(hologramaColor(holo))
            }
            if let match = r.matchedConuee {
                Label("\(String(format: "%.1f", match.conueeKmPerL)) km/L oficial CONUEE",
                      systemImage: "leaf.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else if r.make != nil {
                Label("Sin match en CONUEE", systemImage: "questionmark.diamond")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            if let notes = r.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            TextField("Apodo (opcional)", text: $nickname)
                .textFieldStyle(.roundedBorder)

            if let profile = r.toVehicleProfile(nickname: nickname.isEmpty ? nil : nickname) {
                Button {
                    VehicleProfileService.shared.save(profile)
                    dismiss()
                } label: {
                    Label("Usar este perfil", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.06))
        .cornerRadius(14)
    }

    private func confidencePill(_ pct: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: pct >= 80 ? "checkmark.seal.fill" : "questionmark.diamond.fill")
            Text("\(pct)%")
        }
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(pct >= 80 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
        .foregroundColor(pct >= 80 ? .green : .orange)
        .cornerRadius(8)
    }

    private func hologramaColor(_ h: String) -> Color {
        switch h.uppercased() {
        case "00": return .blue
        case "0": return .green
        case "1": return .yellow
        case "2": return .red
        case "EXENTO": return .mint
        default: return .gray
        }
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            Button {
                showingCamera = true
            } label: {
                Label("Abrir cámara", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Seleccionar de galería", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView(image: Binding(
                get: { capturedImage },
                set: { newImage in
                    capturedImage = newImage
                    if let img = newImage {
                        Task { await analyze(img) }
                    }
                }
            ))
        }
    }

    // MARK: - Actions

    private func analyze(_ image: UIImage) async {
        let sizeKb = Double(image.jpegData(compressionQuality: 0.6)?.count ?? 0) / 1024.0
        AirWayLogger.vision.info(
            "VehicleScanView.analyze image \(image.size.width, privacy: .public)x\(image.size.height, privacy: .public) ~\(String(format: "%.1f", sizeKb), privacy: .public)KB"
        )
        loading = true
        errorMsg = nil
        result = nil
        defer { loading = false }
        do {
            result = try await VehicleVisionAPI.shared.identify(image: image)
            AirWayLogger.vision.info(
                "VehicleScanView got result success=\(self.result?.success ?? false, privacy: .public) matched=\(self.result?.matchedConuee != nil, privacy: .public)"
            )
        } catch {
            errorMsg = "No pudimos identificar: \(error.localizedDescription)"
            AirWayLogger.vision.error("VehicleScanView identify failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// MARK: - UIKit camera wrapper

struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        init(parent: CameraCaptureView) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
