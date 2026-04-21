//
//  AnatomicalSystem.swift
//  AcessNet
//
//  Los 8 sistemas anatómicos de cuerpo completo disponibles en el catálogo
//  público de BioDigital (patrón `male_system_{X}_20`). El atlas usa estos
//  para mostrar distintas vistas del cuerpo completo.
//

import Foundation

enum AnatomicalSystem: String, CaseIterable, Identifiable {
    case cardiovascular
    case respiratory
    case nervous
    case muscular
    case skeletal
    case digestive
    case lymphatic
    case urinary

    var id: String { rawValue }

    var modelId: String {
        modelQueue.first ?? "production/maleAdult/brain"
    }

    /// Cola de modelos en orden de preferencia. Si el primero no está en el
    /// tier developer del usuario, el wrapper intenta los siguientes tras
    /// timeout. Los modelos alternativos son de patologías que muestran el
    /// sistema completo (no solo un órgano aislado).
    var modelQueue: [String] {
        switch self {
        case .cardiovascular:
            return [
                "production/maleAdult/male_system_cardiovascular_20",
                "production/maleAdult/atherosclerosis",
                "production/maleAdult/coronary_artery_disease_v02"
            ]
        case .respiratory:
            return [
                "production/maleAdult/male_system_respiratory_20",
                "production/maleAdult/asthma_v02",
                "production/maleAdult/copd",
                "production/maleAdult/emphysema",
                "production/maleAdult/bronchitis"
            ]
        case .nervous:
            return [
                "production/maleAdult/male_system_nervous_20",
                "production/maleAdult/multiple_sclerosis",       // cerebro + médula + nervios con placas
                "production/maleAdult/peripheral_neuropathy",    // nervios periféricos del cuerpo
                "production/maleAdult/sciatica",                 // columna + pierna
                "production/maleAdult/brain"                     // último fallback
            ]
        case .muscular:
            return [
                "production/maleAdult/male_system_muscular_20",
                "production/maleAdult/sciatica"
            ]
        case .skeletal:
            return [
                "production/maleAdult/male_system_skeletal_20",
                "production/maleAdult/sciatica"
            ]
        case .digestive:
            return [
                "production/maleAdult/male_system_digestive_20"
            ]
        case .lymphatic:
            return [
                "production/maleAdult/male_system_lymphatic_20"
            ]
        case .urinary:
            return [
                "production/maleAdult/male_system_urinary_20"
            ]
        }
    }

    var label: String {
        switch self {
        case .cardiovascular: return String(localized: "Cardiovascular")
        case .respiratory:    return String(localized: "Respiratorio")
        case .nervous:        return String(localized: "Nervioso")
        case .muscular:       return String(localized: "Muscular")
        case .skeletal:       return String(localized: "Esquelético")
        case .digestive:      return String(localized: "Digestivo")
        case .lymphatic:      return String(localized: "Linfático")
        case .urinary:        return String(localized: "Urinario")
        }
    }

    var systemIcon: String {
        switch self {
        case .cardiovascular: return "heart.circle.fill"
        case .respiratory:    return "lungs.fill"
        case .nervous:        return "brain.head.profile"
        case .muscular:       return "figure.strengthtraining.traditional"
        case .skeletal:       return "figure.walk"
        case .digestive:      return "takeoutbag.and.cup.and.straw.fill"
        case .lymphatic:      return "drop.circle.fill"
        case .urinary:        return "drop.fill"
        }
    }

    /// Tinte característico del sistema (para chips y acentos).
    var accentHex: String {
        switch self {
        case .cardiovascular: return "#FF5B5B"
        case .respiratory:    return "#7DD3FC"
        case .nervous:        return "#A78BFA"
        case .muscular:       return "#F472B6"
        case .skeletal:       return "#E5E7EB"
        case .digestive:      return "#F4B942"
        case .lymphatic:      return "#4ADE80"
        case .urinary:        return "#60A5FA"
        }
    }
}
