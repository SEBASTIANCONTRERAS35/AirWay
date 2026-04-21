//
//  BodyScanHubView.swift
//  AcessNet
//
//  Vista principal de la tab BodyScan. Por default muestra el `BodyAtlasView`
//  (hero holográfico con cuerpo humano + órganos interactivos). Los 4 modos
//  especializados (Live · Escanear · Modelo · Anatomy) se abren desde el
//  botón "Modos" del atlas.
//

import SwiftUI

struct BodyScanHubView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.weatherTheme) private var theme
    @StateObject private var storage = BodyScanStorage.shared
    @State private var scanCoordinator = ObjectCaptureCoordinator()
    @State private var activeMode: Mode? = nil
    @State private var showHealthMenu: Bool = false

    /// `nil` → hero atlas. `.xxx` → abrir modo específico en sheet/fullscreen.
    enum Mode: String, CaseIterable, Identifiable {
        case live, scan, saved, anatomy
        var id: String { rawValue }

        var title: String {
            switch self {
            case .live: return "Live"
            case .scan: return "Escanear"
            case .saved: return "Modelo"
            case .anatomy: return "Anatomy"
            }
        }

        var icon: String {
            switch self {
            case .live: return "figure.walk.motion"
            case .scan: return "cube.transparent"
            case .saved: return "arkit"
            case .anatomy: return "lungs.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // Hero por default: atlas del cuerpo humano con órganos interactivos.
            BodyAtlasView { mode in
                activeMode = mode
            }
        }
        .fullScreenCover(item: $activeMode) { mode in
            modeView(for: mode)
        }
        .task(id: scanCoordinator.isCompleted) {
            // Al completar un escaneo, navegar al modelo guardado.
            if scanCoordinator.isCompleted && activeMode == .scan {
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeMode = .saved
                }
            }
        }
        .onDisappear {
            scanCoordinator.cancel()
        }
    }

    /// Renderiza la vista del modo seleccionado dentro del fullScreenCover.
    @ViewBuilder
    private func modeView(for mode: Mode) -> some View {
        ZStack {
            Color(hex: "#0A0A0F").ignoresSafeArea()

            switch mode {
            case .live:
                LiveBodyTrackingView()
            case .scan:
                BodyMeshCaptureView(coordinator: scanCoordinator)
            case .saved:
                SavedScanViewerView(storage: storage)
            case .anatomy:
                AnatomyModeView()
            }

            // Dismiss button floating top-left
            VStack {
                HStack {
                    Button {
                        HapticFeedback.light()
                        activeMode = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .bold))
                            Text("Atlas")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                Spacer()
            }
        }
    }

}

#Preview {
    BodyScanHubView()
        .environmentObject(AppSettings.shared)
}
