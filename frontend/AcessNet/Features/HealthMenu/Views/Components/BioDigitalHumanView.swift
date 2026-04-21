//
//  BioDigitalHumanView.swift
//  AcessNet
//
//  SwiftUI wrapper alrededor del SDK BioDigital HumanKit (XCFramework nativo).
//
//  ── Requisitos según la documentación oficial ────────────────────────
//  1. Archivo `BioDigital.plist` en el bundle con APIKey y APISecret
//     (NO en Info.plist — el SDK lee de `BioDigital.plist` explícitamente).
//  2. Llamada a `HKServices.shared.setup(delegate:)` en el AppDelegate
//     (ver `AcessNetApp.swift`).
//  3. Instanciar `HKHuman(view:)` SOLO después de recibir `onValidSDK`.
//  4. Llamar `human.load(model:) { ... }` con un modelo válido.
//
//  ── Activación del SDK ──────────────────────────────────────────────
//  El SDK se integra vía Swift Package Manager:
//    https://github.com/biodigital-inc/HumanKit.git   (≥ 164.3)
//
//  Sin el paquete enlazado este archivo compila en modo PLACEHOLDER.
//  Para activar: Build Settings → Active Compilation Conditions → HAS_HUMANKIT.
//

import SwiftUI
import UIKit
import SceneKit

#if HAS_HUMANKIT
import HumanKit
#endif

// MARK: - SwiftUI Wrapper

struct BioDigitalHumanView: UIViewRepresentable {

    var bodyState: BodyHealthState
    /// Órgano actualmente en foco (corazón / pulmones / cerebro).
    var focus: BodyPartFocus = .heart
    /// Si `true`, aplica `Visualizer` según el damage del órgano en foco.
    /// `false` deja el modelo con sus colores nativos (útil para el atlas).
    var applyTinting: Bool = true
    /// Si se especifica, carga este modelo en vez del derivado del `focus`.
    /// Permite al atlas mostrar un modelo genérico distinto de los 3 órganos.
    var explicitModelId: String? = nil
    /// Cola completa de modelos a probar. Si se especifica, toma precedencia
    /// sobre `explicitModelId`. Útil cuando el sistema tiene varios fallbacks.
    var explicitModelQueue: [String]? = nil
    var onModelReady: () -> Void
    var onLoadError: (String) -> Void
    var onObjectPicked: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onModelReady: onModelReady,
            onLoadError: onLoadError,
            onObjectPicked: onObjectPicked
        )
    }

    func makeUIView(context: Context) -> UIView {
        #if HAS_HUMANKIT
        // El SDK de BioDigital exige un frame inicial concreto (no `.zero`),
        // de lo contrario el WebView interno no renderiza. Usamos las bounds
        // de la pantalla como base; SwiftUI ajusta después via autoresizing.
        let canvas = UIView(frame: UIScreen.main.bounds)
        canvas.backgroundColor = .clear
        canvas.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        context.coordinator.canvas = canvas

        // Si el SDK ya validó (app lleva tiempo abierta) → crear HKHuman
        // inmediatamente. Si no, esperar la notificación de validación.
        if BioDigitalSDKObserver.shared.isValidSDK {
            context.coordinator.attachHumanIfNeeded()
        } else if BioDigitalSDKObserver.shared.hasResolved {
            // Ya respondió con invalidSDK — nada que hacer.
            context.coordinator.onLoadError(
                String(localized: "SDK BioDigital rechazó las credenciales. Revisa BioDigital.plist y bundle ID.")
            )
        }

        context.coordinator.observeSDKValidation()
        return canvas
        #else
        return makePlaceholderView()
        #endif
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bodyState = bodyState
        context.coordinator.applyTinting = applyTinting
        #if HAS_HUMANKIT
        let queueChanged = context.coordinator.explicitModelQueue != explicitModelQueue
        let idChanged = context.coordinator.explicitModelId != explicitModelId
        if queueChanged || idChanged {
            context.coordinator.explicitModelQueue = explicitModelQueue
            context.coordinator.explicitModelId = explicitModelId
            context.coordinator.reloadForCurrentFocus()
        } else if context.coordinator.focus != focus {
            context.coordinator.focus = focus
            context.coordinator.reloadForCurrentFocus()
        } else {
            context.coordinator.applyBodyStateIfReady()
        }
        #endif
    }

    #if !HAS_HUMANKIT
    private func makePlaceholderView() -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.antialiasingMode = .multisampling4X
        scnView.translatesAutoresizingMaskIntoConstraints = false
        let scene = SCNScene()
        let capsule = SCNCapsule(capRadius: 0.35, height: 1.6)
        capsule.firstMaterial?.diffuse.contents = UIColor(white: 0.85, alpha: 0.95)
        let node = SCNNode(geometry: capsule)
        scene.rootNode.addChildNode(node)
        scnView.scene = scene
        container.addSubview(scnView)

        let label = UILabel()
        label.text = "SDK BioDigital no enlazado\nAgrega HumanKit vía SPM y activa HAS_HUMANKIT"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.white.withAlphaComponent(0.65)
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: container.topAnchor),
            scnView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            scnView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scnView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
        return container
    }
    #endif
}

// MARK: - Coordinator

extension BioDigitalHumanView {

    @MainActor
    final class Coordinator: NSObject {
        let onModelReady: () -> Void
        let onLoadError: (String) -> Void
        let onObjectPicked: (String) -> Void

        weak var canvas: UIView?
        var bodyState: BodyHealthState?
        var focus: BodyPartFocus = .heart
        var applyTinting: Bool = true
        var explicitModelId: String? = nil
        var explicitModelQueue: [String]? = nil
        var modelDidLoad: Bool = false

        /// Cola de modelos a intentar. Si el primario falla con `modelLoadError`,
        /// probamos el siguiente automáticamente.
        private var pendingModelIds: [String] = []

        /// Identifica el intento de carga actual. Se usa para que un timeout
        /// no dispare un fallback si ya se recibió `modelLoaded` o el usuario
        /// cambió de sistema a mitad de carga.
        fileprivate var currentLoadAttempt: UUID?

        #if HAS_HUMANKIT
        var human: HKHuman?
        private var validationObserver: NSObjectProtocol?
        #endif

        init(
            onModelReady: @escaping () -> Void,
            onLoadError: @escaping (String) -> Void,
            onObjectPicked: @escaping (String) -> Void
        ) {
            self.onModelReady = onModelReady
            self.onLoadError = onLoadError
            self.onObjectPicked = onObjectPicked
        }

        deinit {
            #if HAS_HUMANKIT
            if let observer = validationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            #endif
        }

        func observeSDKValidation() {
            #if HAS_HUMANKIT
            guard validationObserver == nil else { return }
            validationObserver = NotificationCenter.default.addObserver(
                forName: BioDigitalSDKObserver.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    if BioDigitalSDKObserver.shared.isValidSDK {
                        self.attachHumanIfNeeded()
                    } else {
                        self.onLoadError(
                            String(localized: "SDK BioDigital rechazó las credenciales.")
                        )
                    }
                }
            }
            #endif
        }

        #if HAS_HUMANKIT

        /// Crea `HKHuman` y dispara el load del modelo si aún no se ha hecho.
        /// Si se especifica `explicitModelId` → lo usa primero. Si no, usa el
        /// modelo derivado del `focus` (órgano específico).
        func attachHumanIfNeeded() {
            guard human == nil, let canvas else { return }

            print("🩺 [BioDigital] SDK válido — creando HKHuman")
            // Ocultamos todo el UI nativo del SDK (menú, tools, info, help,
            // object tree, reset, animation controls, tour) para que solo
            // se vea el modelo 3D limpio. Nuestra UI custom provee navegación.
            let uiOptions: [HumanUIOptions: Bool] = [
                .all: false,
                .tools: false,
                .info: false,
                .animation: false,
                .tour: false,
                .help: false,
                .objectTree: false,
                .reset: false
            ]
            let body = HKHuman(view: canvas, options: uiOptions)
            body.delegate = self
            self.human = body

            // Refuerzo por si el init con options no desactiva todos los elementos.
            body.setupUI(option: .all, value: false)
            body.setupUI(option: .tools, value: false)
            body.setupUI(option: .info, value: false)
            body.setupUI(option: .help, value: false)
            body.setupUI(option: .objectTree, value: false)
            body.setupUI(option: .reset, value: false)
            body.setupUI(option: .animation, value: false)
            body.setupUI(option: .tour, value: false)

            pendingModelIds = buildModelQueue()

            // El ejemplo oficial de BioDigital inserta un delay de 1s para
            // dar tiempo a que el WebView interno del SDK termine de configurarse.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.loadNextModel()
            }
        }

        /// Recarga el modelo cuando el usuario cambia de foco/sistema.
        func reloadForCurrentFocus() {
            guard let human else {
                attachHumanIfNeeded()
                return
            }
            modelDidLoad = false
            pendingModelIds = buildModelQueue()
            let primary = pendingModelIds.first ?? focus.primaryModelId
            print("🩺 [BioDigital] recargando modelo → \(primary)")
            pendingModelIds.removeFirst()
            human.load(model: primary)
        }

        /// Construye la cola de modelos respetando cualquier override del atlas.
        /// Orden de precedencia:
        ///   1. `explicitModelQueue` (lista completa del sistema con fallbacks)
        ///   2. `explicitModelId` (modelo único)
        ///   3. `focus.modelQueue` (órgano del diagnóstico)
        /// + fallbacks generales al final.
        private func buildModelQueue() -> [String] {
            if let queue = explicitModelQueue, !queue.isEmpty {
                return queue + focus.modelQueue + BioDigitalConfig.fallbackModelIds
            }
            if let explicit = explicitModelId {
                return [explicit] + focus.modelQueue + BioDigitalConfig.fallbackModelIds
            }
            return focus.modelQueue + BioDigitalConfig.fallbackModelIds
        }

        /// Intenta cargar el siguiente modelo de la cola. Si falla, se encadena
        /// desde `human(_:modelLoadError:)`. Incluye un timeout de 8s porque
        /// algunos modelos del tier developer se quedan colgados silenciosamente
        /// sin disparar `modelLoadError`.
        func loadNextModel() {
            guard let human else { return }
            guard let next = pendingModelIds.first else {
                print("🩺 [BioDigital] ❌ ningún modelo cargó — revisa permisos del tier")
                onLoadError(String(localized: "Ningún modelo disponible para tu plan BioDigital."))
                return
            }
            pendingModelIds.removeFirst()
            let attemptId = UUID()
            currentLoadAttempt = attemptId
            modelDidLoad = false
            print("🩺 [BioDigital] load(model: \(next)) — quedan \(pendingModelIds.count) fallbacks")
            human.load(model: next)

            // Timeout: si en 8s no se reportó `modelLoaded` ni `modelLoadError`,
            // asumimos que el modelo no es accesible y probamos el siguiente.
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
                guard let self, self.currentLoadAttempt == attemptId else { return }
                guard !self.modelDidLoad else { return }
                print("🩺 [BioDigital] ⏱ timeout cargando \(next) — probando fallback")
                self.loadNextModel()
            }
        }

        func applyBodyStateIfReady() {
            guard modelDidLoad, let human, let state = bodyState else { return }
            guard applyTinting else { return } // atlas usa colores nativos

            // Deterioro continuo del órgano en foco usando su Visualizer
            // específico (HeartVisualizer / LungVisualizer / BrainVisualizer).
            let damage = state.health(for: focus.organ).damageLevel
            focus.apply(damage: damage, on: human)
        }

        #endif
    }
}

// MARK: - HKHumanDelegate (solo con SDK enlazado)

#if HAS_HUMANKIT

extension BioDigitalHumanView.Coordinator: HKHumanDelegate {

    nonisolated func human(_ view: HKHuman, modelLoaded: String) {
        print("🩺 [BioDigital] HKHumanDelegate.modelLoaded: \(modelLoaded)")
        Task { @MainActor [weak self] in
            self?.modelDidLoad = true
            self?.onModelReady()
            self?.applyBodyStateIfReady()
        }
    }

    nonisolated func human(_ view: HKHuman, modelLoadError: String) {
        print("🩺 [BioDigital] ⚠️ modelLoadError: \(modelLoadError) — probando fallback")
        Task { @MainActor [weak self] in
            // Si hay más modelos pendientes, intentar el siguiente. Si no, fallar.
            self?.loadNextModel()
        }
    }

    nonisolated func human(_ view: HKHuman, objectPicked: String, position: [Double]) {
        // DEBUG: imprimir el ID real tocado para poder mapearlo al Visualizer correspondiente.
        print("🩺 [BioDigital] 🎯 objectPicked — ID REAL: \"\(objectPicked)\"")
        Task { @MainActor [weak self] in
            self?.onObjectPicked(objectPicked)
        }
    }

    nonisolated func human(_ view: HKHuman, initScene: String) {}
    nonisolated func human(_ view: HKHuman, objectColor: String, color: HKColor) {}
    nonisolated func human(_ view: HKHuman, chapterTransition: String) {}
    nonisolated func human(_ view: HKHuman, animationComplete: Bool) {}
}

#endif
