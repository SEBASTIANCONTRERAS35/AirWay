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
        let canvas = UIView()
        canvas.backgroundColor = .clear
        canvas.translatesAutoresizingMaskIntoConstraints = false
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
        #if HAS_HUMANKIT
        context.coordinator.applyBodyStateIfReady()
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
        var modelDidLoad: Bool = false

        /// Cola de modelos a intentar. Si el primario falla con `modelLoadError`,
        /// probamos el siguiente automáticamente.
        private var pendingModelIds: [String] = []

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
        func attachHumanIfNeeded() {
            guard human == nil, let canvas else { return }

            print("🩺 [BioDigital] SDK válido — creando HKHuman y cargando modelo")
            let body = HKHuman(view: canvas)
            body.delegate = self
            self.human = body

            // Inicializar cola: modelo primario + fallbacks.
            pendingModelIds = [BioDigitalConfig.defaultModelId] + BioDigitalConfig.fallbackModelIds

            // El ejemplo oficial de BioDigital inserta un delay de 1s para
            // dar tiempo a que el WebView interno del SDK termine de configurarse.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.loadNextModel()
            }
        }

        /// Intenta cargar el siguiente modelo de la cola. Si falla, se encadena
        /// desde `human(_:modelLoadError:)`.
        func loadNextModel() {
            guard let human else { return }
            guard let next = pendingModelIds.first else {
                print("🩺 [BioDigital] ❌ ningún modelo cargó — revisa permisos del tier")
                onLoadError(String(localized: "Ningún modelo disponible para tu plan BioDigital."))
                return
            }
            pendingModelIds.removeFirst()
            print("🩺 [BioDigital] load(model: \(next)) — quedan \(pendingModelIds.count) fallbacks")
            human.load(model: next)
        }

        func applyBodyStateIfReady() {
            guard modelDidLoad, let human, let state = bodyState else { return }

            for organ in BodyHealthState.Organ.allCases {
                let health = state.health(for: organ)
                let rgba = BioDigitalOrganMapper.highlightColor(for: health.damageLevel)
                let color = HKColor()
                color.tint = UIColor(
                    red: CGFloat(rgba.red),
                    green: CGFloat(rgba.green),
                    blue: CGFloat(rgba.blue),
                    alpha: 1.0
                )
                color.opacity = CGFloat(rgba.alpha)

                for objectId in BioDigitalOrganMapper.objectIds(for: organ) {
                    human.scene.color(objectId: objectId, color: color)
                }
            }
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
