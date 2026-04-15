//
//  ARParticlesView.swift
//  AcessNet
//
//  Vista de Realidad Aumentada para visualizar partículas PM2.5 en el aire
//

import SwiftUI
import ARKit
import RealityKit

struct ARParticlesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var arViewModel = ARParticlesViewModel()

    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(arViewModel: arViewModel)
                .ignoresSafeArea()

            // Loading indicator
            if !arViewModel.isTrackingReady {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Initializing AR...")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Preparing particle system")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            // Overlay UI
            VStack {
                // Header
                headerView

                Spacer()

                // Info Panel
                if arViewModel.isTrackingReady {
                    infoPanel
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Controls
            VStack {
                Spacer()

                if arViewModel.isTrackingReady {
                    controlsPanel
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white, .black.opacity(0.3))
                    .shadow(radius: 10)
            }

            Spacer()

            Text("AR Air Quality")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Spacer()

            // Placeholder for balance
            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding()
    }

    // MARK: - Info Panel

    private var infoPanel: some View {
        VStack(spacing: 12) {
            // AQI Indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(aqiColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.5), lineWidth: 2)
                            .scaleEffect(arViewModel.isPulsing ? 1.3 : 1.0)
                            .opacity(arViewModel.isPulsing ? 0 : 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("PM2.5 Concentration")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text("\(Int(arViewModel.currentPM25)) μg/m³")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(aqiLevel)
                        .font(.caption.bold())
                        .foregroundColor(aqiColor)

                    Text("AQI: \(arViewModel.currentAQI)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Particle Count con mensaje de concientización
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("\(arViewModel.visibleParticles) invisible particles")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.4))
                .clipShape(Capsule())

                Text("This is what you breathe every second")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Controls Panel

    private var controlsPanel: some View {
        HStack(spacing: 20) {
            // Decrease density
            Button {
                arViewModel.adjustParticleDensity(by: -10)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white, .black.opacity(0.5))
            }

            // Particle density indicator
            VStack(spacing: 4) {
                Text("Density")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))

                Text("\(Int(arViewModel.particleDensity))%")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Increase density
            Button {
                arViewModel.adjustParticleDensity(by: 10)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
        }
    }

    // MARK: - Computed Properties

    private var aqiColor: Color {
        switch arViewModel.currentAQI {
        case 0..<51: return .green
        case 51..<101: return .yellow
        case 101..<151: return .orange
        case 151..<201: return .red
        default: return .purple
        }
    }

    private var aqiLevel: String {
        switch arViewModel.currentAQI {
        case 0..<51: return "Good"
        case 51..<101: return "Moderate"
        case 101..<151: return "Unhealthy"
        case 151..<201: return "Very Unhealthy"
        default: return "Hazardous"
        }
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arViewModel: ARParticlesViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        configuration.environmentTexturing = .automatic

        arView.session.run(configuration)
        arView.session.delegate = context.coordinator

        // Store reference
        arViewModel.arView = arView

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Update handled by view model
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: arViewModel)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: ARParticlesViewModel

        init(viewModel: ARParticlesViewModel) {
            self.viewModel = viewModel
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            viewModel.handleARFrame(frame)
        }
    }
}

#Preview {
    ARParticlesView()
}
