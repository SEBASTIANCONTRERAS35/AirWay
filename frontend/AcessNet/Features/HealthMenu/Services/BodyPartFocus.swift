//
//  BodyPartFocus.swift
//  AcessNet
//
//  Enum que agrupa los 3 órganos con visualización dinámica: corazón,
//  pulmones y cerebro. Cada uno tiene:
//    · modelId base de BioDigital (con animación si existe)
//    · fallback de modelId por si el principal falla
//    · mapping al `BodyHealthState.Organ` para leer el damageLevel
//    · función `apply(damage:on:)` que delega al Visualizer específico
//

import Foundation

#if HAS_HUMANKIT
import HumanKit
#endif

enum BodyPartFocus: String, CaseIterable, Identifiable {
    case heart
    case lungs
    case brain

    var id: String { rawValue }

    /// Órgano correspondiente en el `BodyHealthState`.
    var organ: BodyHealthState.Organ {
        switch self {
        case .heart: return .heart
        case .lungs: return .lungs
        case .brain: return .brain
        }
    }

    var label: String {
        switch self {
        case .heart: return String(localized: "Corazón")
        case .lungs: return String(localized: "Pulmones")
        case .brain: return String(localized: "Cerebro")
        }
    }

    var systemIcon: String {
        switch self {
        case .heart: return "heart.fill"
        case .lungs: return "lungs.fill"
        case .brain: return "brain.head.profile"
        }
    }

    /// Modelo primario a cargar en BioDigital para este órgano.
    var primaryModelId: String {
        switch self {
        case .heart: return "production/maleAdult/normal_heart_conduction_system"
        case .lungs: return "production/maleAdult/asthma_v02"   // pulmón + bronquios anatómicos
        case .brain: return "production/maleAdult/brain"
        }
    }

    /// Cola de modelos: primario + fallbacks por si el tier del user no los tiene.
    var modelQueue: [String] {
        switch self {
        case .heart:
            return [
                primaryModelId,
                "3Y78",
                "production/maleAdult/coronary_artery_disease_v02"
            ]
        case .lungs:
            return [
                primaryModelId,
                "production/maleAdult/asthma",
                "production/maleAdult/copd",
                "production/maleAdult/emphysema",
                "production/maleAdult/bronchitis"
            ]
        case .brain:
            return [
                primaryModelId,
                "production/maleAdult/stroke",
                "production/maleAdult/concussion"
            ]
        }
    }

    /// Delega al Visualizer específico para aplicar tinting progresivo.
    func apply(damage: Double, on human: AnyObject) {
        #if HAS_HUMANKIT
        switch self {
        case .heart: HeartVisualizer.apply(damage: damage, on: human)
        case .lungs: LungVisualizer.apply(damage: damage, on: human)
        case .brain: BrainVisualizer.apply(damage: damage, on: human)
        }
        #endif
    }
}
