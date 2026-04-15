//
//  ARParticlesViewModel.swift
//  AcessNet
//
//  ViewModel para manejar la lógica de visualización AR de partículas PM2.5
//

import SwiftUI
import ARKit
import RealityKit
import Combine

class ARParticlesViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isTrackingReady: Bool = false
    @Published var currentAQI: Int = 120 // AQI más alto por defecto para mayor impacto
    @Published var currentPM25: Double = 60.0 // PM2.5 elevado
    @Published var visibleParticles: Int = 0
    @Published var particleDensity: Double = 80.0 // Mayor densidad inicial
    @Published var isPulsing: Bool = false

    // Progreso de carga inicial
    private var initialLoadComplete: Bool = false
    private var warmupPhase: Int = 0

    // MARK: - Properties

    var arView: ARView?
    private var particleEntities: [Entity] = []
    private var updateTimer: Timer?
    private var pulseTimer: Timer?

    // Cache de meshes para reutilizar (optimización de rendimiento)
    private var meshCache: [Float: MeshResource] = [:]
    private let meshCacheLock = NSLock() // Thread-safe access
    private let particleBatchSize = 20 // Generar en lotes pequeños para estabilidad

    // MARK: - Constants

    private let maxParticles = 2000 // Optimizado para rendimiento y estabilidad
    private let particleSpawnRadius: Float = 5.0 // Mayor radio para llenar más espacio
    private let particleLifetime: TimeInterval = 12.0 // Optimizado para memoria

    // MARK: - Initialization

    init() {
        // Pre-cachear meshes comunes al inicio
        precacheMeshes()

        startUpdates()
        startPulseAnimation()

        // Simular cambio de AQI basado en ubicación
        simulateAQIChanges()
    }

    private func precacheMeshes() {
        // Pre-generar meshes de tamaños comunes
        let commonSizes: [Float] = [0.006, 0.008, 0.010, 0.012]
        for size in commonSizes {
            meshCache[size] = MeshResource.generateSphere(radius: size)
        }
    }

    deinit {
        updateTimer?.invalidate()
        pulseTimer?.invalidate()
    }

    // MARK: - AR Frame Handling

    func handleARFrame(_ frame: ARFrame) {
        if frame.camera.trackingState == .normal && !isTrackingReady {
            DispatchQueue.main.async {
                self.isTrackingReady = true
            }
            // Iniciar warmup gradual
            startWarmup()
        }

        // Update particles based on camera position (solo si warmup completado)
        if initialLoadComplete {
            updateParticles(cameraTransform: frame.camera.transform)
        }
    }

    private func startWarmup() {
        // Fase 1: Generar primeras 300 partículas rápido
        warmupPhase = 1
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in
            guard let self = self, let arView = self.arView,
                  let frame = arView.session.currentFrame else {
                timer.invalidate()
                return
            }

            if self.warmupPhase == 1 && self.particleEntities.count < 300 {
                for _ in 0..<15 {
                    self.createParticle(near: frame.camera.transform, in: arView)
                }
            } else if self.warmupPhase == 1 {
                // Pasar a fase 2
                self.warmupPhase = 2
            } else if self.warmupPhase == 2 && self.particleEntities.count < 800 {
                // Fase 2: Siguiente 500 partículas más lento
                for _ in 0..<10 {
                    self.createParticle(near: frame.camera.transform, in: arView)
                }
            } else if self.warmupPhase == 2 {
                // Warmup completado
                self.initialLoadComplete = true
                timer.invalidate()
            }
        }
    }

    // MARK: - Particle Management

    private func updateParticles(cameraTransform: simd_float4x4) {
        guard let arView = arView else { return }

        // Calculate target particle count based on AQI
        let targetCount = Int(Double(maxParticles) * (particleDensity / 100.0) * (Double(currentAQI) / 200.0))

        // Add new particles in batches to avoid blocking
        let currentCount = particleEntities.count
        if currentCount < targetCount {
            let needed = min(particleBatchSize, targetCount - currentCount)

            // Generar en main thread pero en pequeños batches
            for _ in 0..<needed {
                createParticle(near: cameraTransform, in: arView)
            }

            visibleParticles = particleEntities.count
        }
    }

    private func createParticle(near cameraTransform: simd_float4x4, in arView: ARView) {
        // Random position around camera - espacio 3D completo
        let randomX = Float.random(in: -particleSpawnRadius...particleSpawnRadius)
        let randomY = Float.random(in: -2.0...3.0) // Mayor rango vertical
        let randomZ = Float.random(in: -particleSpawnRadius...particleSpawnRadius)

        let cameraPosition = simd_make_float3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let particlePosition = cameraPosition + simd_float3(randomX, randomY, randomZ)

        // Variar tamaño de partículas para efecto realista
        let sizeVariation = Float.random(in: 0.7...1.5)
        let finalSize = particleSize * sizeVariation

        // Usar mesh cacheado más cercano para máxima performance (thread-safe)
        let particleMesh: MeshResource
        meshCacheLock.lock()
        let closestSize = meshCache.keys.min(by: { abs($0 - finalSize) < abs($1 - finalSize) })
        if let closest = closestSize, let cached = meshCache[closest] {
            particleMesh = cached
            meshCacheLock.unlock()
        } else {
            meshCacheLock.unlock()
            // Fallback: crear nuevo solo si no hay cache
            particleMesh = MeshResource.generateSphere(radius: finalSize)
        }

        // Variar transparencia para profundidad visual
        let alphaVariation = Float.random(in: 0.4...0.9)
        var adjustedColor = particleColor
        adjustedColor = adjustedColor.withAlphaComponent(CGFloat(alphaVariation))

        let particleMaterial = SimpleMaterial(
            color: adjustedColor,
            isMetallic: false
        )

        let particleEntity = ModelEntity(
            mesh: particleMesh,
            materials: [particleMaterial]
        )

        particleEntity.position = particlePosition

        // Animación más compleja: flotación en múltiples direcciones
        let floatX = Float.random(in: -0.2...0.2)
        let floatY = Float.random(in: 0.2...0.5) // Siempre flotan hacia arriba
        let floatZ = Float.random(in: -0.2...0.2)

        let floatAnimation = Transform(
            translation: particlePosition + simd_float3(floatX, floatY, floatZ)
        )

        let duration = Double.random(in: 3.0...6.0) // Movimiento más lento y orgánico
        particleEntity.move(
            to: floatAnimation,
            relativeTo: nil,
            duration: duration,
            timingFunction: .easeInOut
        )

        // Add to scene
        let anchor = AnchorEntity(world: particlePosition)
        anchor.addChild(particleEntity)
        arView.scene.addAnchor(anchor)

        // Store reference
        particleEntities.append(anchor)

        // Schedule removal
        DispatchQueue.main.asyncAfter(deadline: .now() + particleLifetime) { [weak self, weak arView] in
            guard let self = self, let arView = arView else { return }
            self.removeParticle(anchor, from: arView)
        }
    }

    private func removeParticle(_ particle: Entity, from arView: ARView) {
        guard let anchor = particle as? AnchorEntity else { return }
        arView.scene.removeAnchor(anchor)
        particleEntities.removeAll { $0 == particle }
    }

    private func removeOldParticles() {
        // Particles are automatically removed after lifetime
    }

    // MARK: - Particle Appearance

    private var particleSize: Float {
        // Partículas más grandes y visibles para impacto
        let baseSize: Float = 0.008 // Aumentado de 0.005
        let sizeFactor = Float(currentPM25 / 100.0)
        return baseSize + (baseSize * sizeFactor * 0.8) // Mayor variación
    }

    private var particleColor: UIColor {
        // Colores más intensos y visibles para concientización
        switch currentAQI {
        case 0..<51:
            return UIColor.green.withAlphaComponent(0.7)
        case 51..<101:
            return UIColor.yellow.withAlphaComponent(0.75)
        case 101..<151:
            return UIColor.orange.withAlphaComponent(0.85)
        case 151..<201:
            return UIColor.red.withAlphaComponent(0.9)
        default:
            return UIColor.purple.withAlphaComponent(0.95)
        }
    }

    // MARK: - User Controls

    func adjustParticleDensity(by amount: Double) {
        particleDensity = max(0, min(100, particleDensity + amount))
    }

    // MARK: - Simulation

    private func simulateAQIChanges() {
        // Simular cambios en AQI cada 5 segundos
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Variar AQI ligeramente
            let variation = Int.random(in: -10...10)
            let newAQI = max(0, min(500, self.currentAQI + variation))

            DispatchQueue.main.async {
                withAnimation {
                    self.currentAQI = newAQI
                    self.currentPM25 = Double(newAQI) * 0.5 // Aproximación PM2.5
                }
            }
        }
    }

    // MARK: - Animations

    private func startUpdates() {
        // Actualización más frecuente para regeneración constante de partículas
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self, let arView = self.arView else { return }

            if let frame = arView.session.currentFrame {
                self.updateParticles(cameraTransform: frame.camera.transform)
            }
        }
    }

    private func startPulseAnimation() {
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1.0)) {
                    self?.isPulsing = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self?.isPulsing = false
                    }
                }
            }
        }
    }

    // MARK: - Location-based AQI

    func updateAQI(for location: CLLocationCoordinate2D) {
        // Aquí podrías integrar con tu API de calidad del aire
        // Por ahora, simular basado en ubicación
        let simulatedAQI = Int.random(in: 30...150)

        DispatchQueue.main.async {
            withAnimation {
                self.currentAQI = simulatedAQI
                self.currentPM25 = Double(simulatedAQI) * 0.5
            }
        }
    }
}

// MARK: - Location Import

import CoreLocation
