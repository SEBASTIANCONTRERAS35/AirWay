//
//  PPIToBodyHealthMapper.swift
//  AcessNet
//
//  Traduce datos fisiológicos reales (PPI + biométricos + AQI + perfil de
//  vulnerabilidad) a BodyHealthState por órgano.
//
//  Coeficientes basados en literatura 2020–2025:
//  · Pope et al. (2020) — PM2.5 × función pulmonar
//  · Brook & Rajagopalan (2021) — PM2.5 × variabilidad cardíaca
//  · Delfino et al. (2022) — O3/NO2 × inflamación vía aérea
//  · Calderón-Garcidueñas (2023) — PM2.5 ultrafino × neuroinflamación
//
//  Los valores son HEURÍSTICOS calibrados para rangos realistas de CDMX.
//  No son diagnóstico clínico — solo visualización pedagógica.
//

import Foundation

enum PPIToBodyHealthMapper {

    /// Input agregado. Todos los campos son opcionales para degradar grácilmente
    /// cuando falten datos del Watch / sensores.
    struct Input {
        let ppi: PPIScoreData?
        let biometrics: BiometricUpdateData?
        let aqi: AQIUpdateData?
        let cigarettes: CigaretteData?
        let vulnerability: VulnerabilityProfile

        /// Estado por defecto si no hay Watch conectado ni AQI: asume un día
        /// típico de CDMX (AQI ~100, PM2.5 ~35).
        static let demoFallback = Input(
            ppi: nil,
            biometrics: nil,
            aqi: AQIUpdateData(
                aqi: 100,
                pm25: 35,
                pm10: 60,
                no2: 45,
                o3: 70,
                dominantPollutant: "PM2.5",
                location: "CDMX",
                qualityLevel: "Moderado",
                confidence: 0.5,
                timestamp: Date()
            ),
            cigarettes: nil,
            vulnerability: VulnerabilityProfile()
        )
    }

    // MARK: - Public API

    static func map(_ input: Input) -> BodyHealthState {
        let mult = input.vulnerability.multiplier

        return BodyHealthState(
            lungs: computeLungs(input, mult: mult),
            nose: computeNose(input, mult: mult),
            brain: computeBrain(input, mult: mult),
            throat: computeThroat(input, mult: mult),
            heart: computeHeart(input, mult: mult),
            skin: computeSkin(input, mult: mult)
        )
    }

    // MARK: - Órgano por órgano

    /// Pulmones: PM2.5 + SpO2 drop + respiratory rate deviation + cigarettes acumulados.
    private static func computeLungs(_ input: Input, mult: Double) -> OrganHealth {
        var damage: Double = 0.05 // baseline sano

        // PM2.5: 50 µg/m³ → +10% damage
        if let pm25 = input.aqi?.pm25 {
            damage += pm25 * 0.002
        }

        // SpO2 drop desde 98%: cada punto = +3% damage
        if let spO2 = input.biometrics?.spO2, spO2 < 98 {
            damage += (98 - spO2) * 0.03
        }

        // Respiratory rate desviación absoluta (baseline ~14 rpm)
        if let resp = input.biometrics?.respiratoryRate {
            damage += min(abs(resp - 14) * 0.015, 0.15)
        }

        // Cigarette-equivalent acumulado del día (5 cig = +10%)
        if let cig = input.cigarettes?.cigarettesToday {
            damage += min(cig * 0.02, 0.25)
        }

        // PPI respScore (0–100) — si viene bajo, refuerza damage
        if let respScore = input.ppi?.components.respScore {
            damage += (1 - respScore / 100.0) * 0.15
        }

        damage *= mult

        var conditions: [EnvironmentalCondition] = []
        if let pm25 = input.aqi?.pm25, pm25 > 35 { conditions.append(.pm25Exposure) }
        if let no2 = input.aqi?.no2, no2 > 100 { conditions.append(.no2Exposure) }
        if damage > 0.25 { conditions.append(.bronchialIrritation) }

        return OrganHealth(damageLevel: clamp(damage), activeConditions: conditions)
    }

    /// Nariz: NO2 + PM10 + estación (rinitis alérgica).
    private static func computeNose(_ input: Input, mult: Double) -> OrganHealth {
        var damage: Double = 0.04

        if let no2 = input.aqi?.no2 {
            damage += no2 * 0.003 // 100 µg/m³ → +30%
        }
        if let pm10 = input.aqi?.pm10 {
            damage += pm10 * 0.0015
        }

        damage *= mult

        var conditions: [EnvironmentalCondition] = []
        if let no2 = input.aqi?.no2, no2 > 80 { conditions.append(.rhinitis) }
        if let pm10 = input.aqi?.pm10, pm10 > 50 { conditions.append(.pm25Exposure) }

        return OrganHealth(damageLevel: clamp(damage), activeConditions: conditions)
    }

    /// Cerebro: PM2.5 crónico (neuroinflamación) + PPI score global.
    private static func computeBrain(_ input: Input, mult: Double) -> OrganHealth {
        var damage: Double = 0.03

        // PM2.5 actúa lento en cerebro, coef más bajo que pulmones
        if let pm25 = input.aqi?.pm25 {
            damage += pm25 * 0.001
        }

        // PPI score elevado (zona roja) → estrés sistémico → cerebro afectado
        if let score = input.ppi?.score {
            damage += Double(score) / 100.0 * 0.2
        }

        damage *= mult

        var conditions: [EnvironmentalCondition] = []
        if let pm25 = input.aqi?.pm25, pm25 > 55 { conditions.append(.migraine) }

        return OrganHealth(damageLevel: clamp(damage), activeConditions: conditions)
    }

    /// Garganta/Tráquea: O3 + NO2 irritación.
    private static func computeThroat(_ input: Input, mult: Double) -> OrganHealth {
        var damage: Double = 0.04

        if let o3 = input.aqi?.o3 {
            damage += o3 * 0.002 // O3 irrita vía aérea superior
        }
        if let no2 = input.aqi?.no2 {
            damage += no2 * 0.0015
        }

        damage *= mult

        var conditions: [EnvironmentalCondition] = []
        if let o3 = input.aqi?.o3, o3 > 100 { conditions.append(.o3Exposure) }
        if damage > 0.2 { conditions.append(.bronchialIrritation) }

        return OrganHealth(damageLevel: clamp(damage), activeConditions: conditions)
    }

    /// Corazón: HR elevado + HRV bajo + PM2.5 cardiovascular.
    private static func computeHeart(_ input: Input, mult: Double) -> OrganHealth {
        var damage: Double = 0.03

        // HR score del PPI (0–100 donde 100 es peor desviación)
        if let hrScore = input.ppi?.components.hrScore {
            damage += (1 - hrScore / 100.0) * 0.2
        }
        if let hrvScore = input.ppi?.components.hrvScore {
            damage += (1 - hrvScore / 100.0) * 0.2
        }

        // PM2.5 → enfermedad cardiovascular (Brook 2021)
        if let pm25 = input.aqi?.pm25 {
            damage += pm25 * 0.001
        }

        damage *= mult

        var conditions: [EnvironmentalCondition] = []
        if let pm25 = input.aqi?.pm25, pm25 > 35 { conditions.append(.pm25Exposure) }

        return OrganHealth(damageLevel: clamp(damage), activeConditions: conditions)
    }

    /// Piel: PM2.5 oxidativo + exposición UV (no disponible, ignoramos).
    private static func computeSkin(_ input: Input, mult: Double) -> OrganHealth {
        var damage: Double = 0.02

        if let pm25 = input.aqi?.pm25 {
            damage += pm25 * 0.0008
        }

        damage *= mult

        return OrganHealth(damageLevel: clamp(damage), activeConditions: [])
    }

    // MARK: - Helpers

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0.0), 1.0)
    }
}

// MARK: - Treatment generator

extension PPIToBodyHealthMapper {

    /// Genera tratamientos priorizados según los órganos más afectados.
    /// La prioridad se deriva del damageLevel: órganos más dañados primero.
    static func treatments(for state: BodyHealthState,
                           input: Input) -> [Treatment] {
        let organs = BodyHealthState.Organ.allCases
            .map { ($0, state.health(for: $0)) }
            .sorted { $0.1.damageLevel > $1.1.damageLevel }

        var treatments: [Treatment] = []
        var priority = 1

        for (organ, health) in organs where health.severity != .healthy {
            for template in templates(for: organ, health: health) {
                treatments.append(Treatment(
                    title: template.title,
                    subtitle: template.subtitle,
                    iconSystemName: template.icon,
                    priority: priority
                ))
                priority += 1
            }
        }

        // Recomendación general: mascarilla si PM2.5 alto
        if let pm25 = input.aqi?.pm25, pm25 > 35 {
            treatments.insert(
                Treatment(
                    title: String(localized: "Usa cubrebocas N95"),
                    subtitle: String(localized: "PM2.5 \(Int(pm25)) µg/m³ · reduce exposición 95%"),
                    iconSystemName: "facemask.fill",
                    priority: 0
                ),
                at: 0
            )
        }

        if treatments.isEmpty {
            treatments.append(Treatment(
                title: String(localized: "Tu cuerpo está en buen estado"),
                subtitle: String(localized: "Mantén los hábitos saludables"),
                iconSystemName: "checkmark.seal.fill",
                priority: 0
            ))
        }

        return Array(treatments.prefix(8))
    }

    private struct TreatmentTemplate {
        let title: String
        let subtitle: String
        let icon: String
    }

    private static func templates(for organ: BodyHealthState.Organ,
                                  health: OrganHealth) -> [TreatmentTemplate] {
        switch organ {
        case .lungs:
            return [
                TreatmentTemplate(
                    title: String(localized: "Evita ejercicio al aire libre"),
                    subtitle: String(localized: "Pulmones con \(health.severity.label.lowercased()) irritación"),
                    icon: "figure.run.circle.fill"
                ),
                TreatmentTemplate(
                    title: String(localized: "Hidratación extra (2L agua)"),
                    subtitle: String(localized: "Diluye mucus y facilita expulsión de partículas"),
                    icon: "drop.fill"
                )
            ]
        case .heart:
            return [TreatmentTemplate(
                title: String(localized: "Reduce esfuerzo cardiovascular"),
                subtitle: String(localized: "HR/HRV desviados del baseline saludable"),
                icon: "heart.circle.fill"
            )]
        case .brain:
            return [TreatmentTemplate(
                title: String(localized: "Descanso mental 20 min"),
                subtitle: String(localized: "PM2.5 ultrafino puede causar fatiga cognitiva"),
                icon: "brain.head.profile"
            )]
        case .throat:
            return [TreatmentTemplate(
                title: String(localized: "Té caliente con miel"),
                subtitle: String(localized: "Calma irritación por O₃ / NO₂"),
                icon: "cup.and.saucer.fill"
            )]
        case .nose:
            return [TreatmentTemplate(
                title: String(localized: "Lavado nasal con solución salina"),
                subtitle: String(localized: "Limpia partículas depositadas en mucosa"),
                icon: "nose"
            )]
        case .skin:
            return [TreatmentTemplate(
                title: String(localized: "Limpieza facial al llegar a casa"),
                subtitle: String(localized: "PM2.5 causa estrés oxidativo en piel"),
                icon: "hands.sparkles.fill"
            )]
        }
    }
}
