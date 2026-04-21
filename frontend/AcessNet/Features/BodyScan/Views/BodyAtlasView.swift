//
//  BodyAtlasView.swift
//  AcessNet
//
//  Hero view del tab Body — el modelo 3D de BioDigital ocupa TODA la pantalla
//  como protagonista. Los controles (sistemas, diagnóstico, modos) son overlays
//  translúcidos flotantes encima del modelo.
//
//  Diseño inmersivo tipo "visor médico" premium.
//

import SwiftUI

struct BodyAtlasView: View {
    @Environment(\.weatherTheme) private var theme
    @State private var viewModel = HealthMenuViewModel()
    @State private var presentedFocus: BodyPartFocus? = nil
    @State private var activeSystem: AnatomicalSystem = .nervous

    /// Sistemas mostrados en el carrusel (excluimos `cardiovascular` porque
    /// su diagnóstico ya está accesible via el chip de Corazón).
    private var availableSystems: [AnatomicalSystem] {
        AnatomicalSystem.allCases.filter { $0 != .cardiovascular }
    }

    /// Órgano por default al que caer si el modelo de sistema falla.
    /// Evita que al timeout de `male_system_nervous_20` se cargue el corazón.
    private var fallbackFocus: BodyPartFocus {
        switch activeSystem {
        case .nervous: return .brain
        case .respiratory: return .lungs
        case .cardiovascular: return .heart
        // Sistemas sin órgano directamente relacionado → usar cerebro (visualmente neutro)
        case .muscular, .skeletal, .digestive, .lymphatic, .urinary: return .brain
        }
    }
    @State private var scanLineProgress: CGFloat = 0
    @State private var showModesMenu: Bool = false
    @State private var isModelReady: Bool = false

    var onOpenMode: (BodyScanHubView.Mode) -> Void

    var body: some View {
        ZStack {
            // 1. Modelo 3D a pantalla completa (protagonista)
            bodyCanvas
                .ignoresSafeArea()

            // 2. Overlays encima del modelo
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }
            .padding(.top, 50)
            .padding(.bottom, AppConstants.enhancedTabBarTotalHeight + 6)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                scanLineProgress = 1
            }
        }
        .fullScreenCover(item: $presentedFocus) { focus in
            HealthMenuView(initialFocus: focus)
        }
    }

    // MARK: - Body canvas (fullscreen)

    private var bodyCanvas: some View {
        ZStack {
            // Fondo base que respeta el tema activo (oscuro en weather, claro en AirWay).
            theme.pageBackground.ignoresSafeArea()

            // Modelo BioDigital ocupando todo
            BioDigitalHumanView(
                bodyState: viewModel.bodyState,
                focus: fallbackFocus,
                applyTinting: false,
                explicitModelQueue: activeSystem.modelQueue,
                onModelReady: { isModelReady = true },
                onLoadError: { _ in },
                onObjectPicked: handleObjectPicked
            )

            // Scan line holográfica animada encima del modelo
            GeometryReader { geo in
                LinearGradient(
                    colors: [
                        .clear,
                        Color(hex: activeSystem.accentHex).opacity(theme.isAirWay ? 0.12 : 0.18),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .offset(y: (geo.size.height + 100) * scanLineProgress - 100)
                .blendMode(theme.isAirWay ? .multiply : .plusLighter)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()

            // Viñeteo radial para destacar el modelo.
            // En AirWay: tinte navy sutil (claro a oscuro en bordes).
            // En weather: negro translúcido en bordes.
            RadialGradient(
                colors: [
                    .clear,
                    theme.isAirWay
                        ? Color(hex: "#0A1D4D").opacity(0.08)
                        : Color.black.opacity(0.55)
                ],
                center: .center,
                startRadius: 180,
                endRadius: 500
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Overlay loading inicial
            if !isModelReady {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 10) {
                        ProgressView().tint(.white).scaleEffect(1.2)
                        Text("Cargando \(activeSystem.label.lowercased())…")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Top bar (compacta, flotante)

    private var topBar: some View {
        HStack(spacing: 10) {
            // Badge sistema activo
            HStack(spacing: 6) {
                Image(systemName: activeSystem.systemIcon)
                    .font(.system(size: 11, weight: .bold))
                VStack(alignment: .leading, spacing: 0) {
                    Text("BODY ATLAS")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.55))
                    Text(activeSystem.label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .foregroundColor(Color(hex: activeSystem.accentHex))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color(hex: activeSystem.accentHex).opacity(0.4), lineWidth: 1))
            )

            Spacer()

            // Badge AQI
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.currentAQIBadge.tint)
                    .frame(width: 8, height: 8)
                Text("AQI \(viewModel.currentAQIBadge.aqi)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(viewModel.currentAQIBadge.tint.opacity(0.5), lineWidth: 1))
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Bottom panel (sistemas + diagnóstico + modos)

    private var bottomPanel: some View {
        VStack(spacing: 10) {
            if showModesMenu {
                modesMenuExpanded
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            systemsCarousel

            HStack(spacing: 10) {
                diagnosticStrip
                modesToggleButton
            }
        }
        .padding(.horizontal, 14)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: showModesMenu)
    }

    // MARK: - Systems carousel

    private var systemsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(availableSystems) { system in
                    systemChip(system)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func systemChip(_ system: AnatomicalSystem) -> some View {
        let isActive = activeSystem == system
        let accent = Color(hex: system.accentHex)

        return Button {
            guard !isActive else { return }
            HapticFeedback.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                activeSystem = system
                isModelReady = false
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: system.systemIcon)
                    .font(.system(size: 10, weight: .semibold))
                Text(system.label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(isActive ? .white : accent.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isActive ? accent.opacity(0.5) : Color.black.opacity(0.4))
                    .overlay(
                        Capsule()
                            .stroke(isActive ? accent : accent.opacity(0.3), lineWidth: 1)
                    )
                    .background(Capsule().fill(.ultraThinMaterial))
            )
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Diagnostic strip (3 órganos)

    private var diagnosticStrip: some View {
        HStack(spacing: 6) {
            ForEach(BodyPartFocus.allCases) { focus in
                diagnosticDot(focus: focus)
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
        )
        .clipShape(Capsule())
    }

    private func diagnosticDot(focus: BodyPartFocus) -> some View {
        let damage = viewModel.bodyState.health(for: focus.organ).damageLevel
        let severity = OrganHealth(damageLevel: damage).severity

        return Button {
            HapticFeedback.light()
            presentedFocus = focus
        } label: {
            ZStack {
                Circle()
                    .fill(severity.tint.opacity(0.22))
                Circle()
                    .stroke(severity.tint.opacity(0.75), lineWidth: 1)
                Image(systemName: focus.systemIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(severity.tint)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Diagnóstico \(focus.label) · \(severity.label)")
    }

    // MARK: - Modes button

    private var modesToggleButton: some View {
        Button {
            HapticFeedback.light()
            withAnimation { showModesMenu.toggle() }
        } label: {
            Image(systemName: showModesMenu ? "xmark" : "square.grid.2x2.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                )
        }
    }

    private var modesMenuExpanded: some View {
        HStack(spacing: 8) {
            modeButton(.live, icon: "figure.walk.motion", label: "Live")
            modeButton(.scan, icon: "cube.transparent", label: "Escanear")
            modeButton(.anatomy, icon: "lungs.fill", label: "Anatomy")
            modeButton(.saved, icon: "arkit", label: "Modelo")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.1), lineWidth: 1))
        )
    }

    private func modeButton(_ mode: BodyScanHubView.Mode,
                            icon: String,
                            label: String) -> some View {
        Button {
            HapticFeedback.light()
            showModesMenu = false
            onOpenMode(mode)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 1))
            )
        }
    }

    // MARK: - Object picker

    private func handleObjectPicked(_ objectId: String) {
        let lowered = objectId.lowercased()
        let target: BodyPartFocus?
        if lowered.contains("brain") || lowered.contains("cerebr") || lowered.contains("gyrus") {
            target = .brain
        } else if lowered.contains("lung") || lowered.contains("bronch") || lowered.contains("asthma") || lowered.contains("trachea") {
            target = .lungs
        } else if lowered.contains("heart") || lowered.contains("ventricle") || lowered.contains("atrium") || lowered.contains("aorta") || lowered.contains("coronary") {
            target = .heart
        } else {
            target = nil
        }

        if let target {
            HapticFeedback.light()
            presentedFocus = target
        }
    }
}

#Preview {
    BodyAtlasView(onOpenMode: { _ in })
}
