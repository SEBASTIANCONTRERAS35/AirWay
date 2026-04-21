//
//  HeartModelSelector.swift
//  AcessNet
//
//  Mapea el `damageLevel` calculado por PPIToBodyHealthMapper a un modelo
//  específico del catálogo de BioDigital, de modo que el corazón visualizado
//  en HealthMenu refleje la severidad real del usuario.
//
//  Los IDs (`stageId`) se obtienen del portal BioDigital (human.biodigital.com
//  → Content Library → copiar ID de la URL del viewer).
//

import Foundation

enum HeartModelSelector {

    /// 5 etapas de progresión desde corazón sano hasta insuficiencia crítica.
    /// Cada etapa tiene un ID de modelo BioDigital y un rango de damageLevel.
    enum Stage: String, CaseIterable, Identifiable {
        case healthy         // 0.00 – 0.25 · corazón anatómico normal
        case mildRisk        // 0.25 – 0.45 · hipertensión leve
        case moderateDisease // 0.45 – 0.65 · coronary artery disease (CAD)
        case severePathology // 0.65 – 0.85 · infarto / blockages
        case critical        // 0.85 – 1.00 · heart failure / cardiomyopathy

        var id: String { rawValue }

        /// ID del modelo en el catálogo BioDigital.
        /// Todos los IDs están verificados contra el catálogo público de
        /// `human.biodigital.com` (títulos confirmados por el servidor).
        var modelId: String {
            switch self {
            case .healthy:
                // Cardiac Conduction System — corazón normal con animación
                // del latido sinusal (mejor visual para "sano").
                return "production/maleAdult/normal_heart_conduction_system"
            case .mildRisk:
                // Atherosclerosis — placas iniciales en arterias coronarias.
                return "production/maleAdult/atherosclerosis"
            case .moderateDisease:
                // Coronary Artery Disease — CAD establecida, arterias con
                // bloqueos visibles.
                return "production/maleAdult/coronary_artery_disease_v02"
            case .severePathology:
                // Myocardial Infarction — infarto activo, necrosis visible
                // en el músculo cardiaco.
                return "production/maleAdult/myocardial_infarction"
            case .critical:
                // Congestive Heart Failure — insuficiencia cardíaca,
                // corazón dilatado (resultado crónico de exposición).
                return "production/maleAdult/congestive_heart_failure"
            }
        }

        /// Modelos alternativos si el primario falla (fallback queue).
        /// Orden: más específico → más genérico.
        var fallbackModelIds: [String] {
            switch self {
            case .healthy:
                return [
                    "production/maleAdult/normal_heart_conduction_system",
                    "3Y78"
                ]
            case .mildRisk:
                return [
                    "production/maleAdult/atherosclerosis",
                    "production/maleAdult/atrial_fibrillation"
                ]
            case .moderateDisease:
                return [
                    "production/maleAdult/coronary_artery_disease",
                    "production/maleAdult/myocardial_ischemia",
                    "3Y78"
                ]
            case .severePathology:
                return [
                    "production/maleAdult/ventricular_fibrillation",
                    "3Y78"
                ]
            case .critical:
                return [
                    "production/maleAdult/dilated_cardiomyopathy",
                    "production/maleAdult/myocardial_infarction",
                    "3Y78"
                ]
            }
        }

        /// Rango superior del damageLevel para esta etapa (el inferior se infiere).
        var damageUpperBound: Double {
            switch self {
            case .healthy:         return 0.25
            case .mildRisk:        return 0.45
            case .moderateDisease: return 0.65
            case .severePathology: return 0.85
            case .critical:        return 1.01 // incluye 1.0
            }
        }

        /// Etiqueta visible para el usuario en el HUD.
        var label: String {
            switch self {
            case .healthy:         return String(localized: "Corazón sano")
            case .mildRisk:        return String(localized: "Riesgo leve")
            case .moderateDisease: return String(localized: "Enfermedad moderada")
            case .severePathology: return String(localized: "Patología severa")
            case .critical:        return String(localized: "Estado crítico")
            }
        }

        /// Descripción corta para mostrar como context del modelo cargado.
        var clinicalHint: String {
            switch self {
            case .healthy:         return String(localized: "Anatomía normal, sin patología visible")
            case .mildRisk:        return String(localized: "Hipertensión · engrosamiento del músculo")
            case .moderateDisease: return String(localized: "Enfermedad coronaria · placas arteriales")
            case .severePathology: return String(localized: "Bloqueos coronarios · infarto activo")
            case .critical:        return String(localized: "Insuficiencia cardíaca · dilatación")
            }
        }

    }

    // MARK: - Selector

    /// Elige la etapa correspondiente al damageLevel.
    static func stage(for damage: Double) -> Stage {
        let clamped = min(max(damage, 0.0), 1.0)
        return Stage.allCases.first { clamped < $0.damageUpperBound } ?? .critical
    }

    /// Model ID primario a cargar en BioDigital para un damage dado.
    static func modelId(for damage: Double) -> String {
        stage(for: damage).modelId
    }

    /// Cola completa de modelos: primario + fallbacks para tolerar que algún
    /// modelo no esté disponible en el tier developer del usuario.
    static func modelQueue(for damage: Double) -> [String] {
        let s = stage(for: damage)
        var queue = [s.modelId]
        queue.append(contentsOf: s.fallbackModelIds.filter { $0 != s.modelId })
        return queue
    }
}
