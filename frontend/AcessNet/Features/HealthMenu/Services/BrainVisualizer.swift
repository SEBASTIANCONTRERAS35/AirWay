//
//  BrainVisualizer.swift
//  AcessNet
//
//  Aplica deterioro visual progresivo a UN solo modelo de cerebro de BioDigital.
//  Usa modelo base `production/maleAdult/brain`.
//
//  Narrativa: la PM2.5 ultrafina (UFP, <0.1µm) cruza la barrera hematoencefálica
//  y causa neuroinflamación (Calderón-Garcidueñas 2023). El visual representa:
//    · 0.00-0.30 → cerebro rosado normal con buena perfusión
//    · 0.30-0.60 → tinte naranja (inflamación, reducción de sinapsis)
//    · 0.60-0.85 → rojo (daño vascular, microinfartos)
//    · 0.85-1.00 → tonos oscuros (atrofia, neurodegeneración)
//

import Foundation
import UIKit

#if HAS_HUMANKIT
import HumanKit
#endif

enum BrainObjectIds {
    /// Patrón confirmado vía objectPicked: `bd_brain-{part}_ID`
    /// (sin `_glass`, sin sufijo numérico).

    private static let prefix = "bd_brain-"
    private static let suffix = "_ID"

    private static func id(_ part: String) -> String {
        "\(prefix)\(part)\(suffix)"
    }

    /// Todos los giros y lóbulos corticales de la superficie cerebral.
    /// Cada hemisferio (left/right) tiene sus propias divisiones.
    static let wholeBrain: [String] = [
        // === HEMISFERIO DERECHO ===
        // Lóbulo frontal
        id("right_superior_frontal_gyrus"),
        id("right_middle_frontal_gyrus"),
        id("right_inferior_frontal_gyrus"),
        id("right_precentral_gyrus"),
        id("right_frontal_lobe"),

        // Lóbulo parietal
        id("right_postcentral_gyrus"),
        id("right_superior_parietal_lobule"),
        id("right_inferior_parietal_lobule"),
        id("right_supramarginal_gyrus"),
        id("right_angular_gyrus"),
        id("right_parietal_lobe"),

        // Lóbulo temporal
        id("right_superior_temporal_gyrus"),
        id("right_middle_temporal_gyrus"),
        id("right_inferior_temporal_gyrus"),
        id("right_temporal_lobe"),

        // Lóbulo occipital
        id("right_superior_occipital_gyrus"),
        id("right_middle_occipital_gyrus"),
        id("right_inferior_occipital_gyrus"),
        id("right_occipital_lobe"),

        // === HEMISFERIO IZQUIERDO ===
        id("left_superior_frontal_gyrus"),
        id("left_middle_frontal_gyrus"),
        id("left_inferior_frontal_gyrus"),
        id("left_precentral_gyrus"),
        id("left_frontal_lobe"),

        id("left_postcentral_gyrus"),
        id("left_superior_parietal_lobule"),
        id("left_inferior_parietal_lobule"),
        id("left_supramarginal_gyrus"),
        id("left_angular_gyrus"),
        id("left_parietal_lobe"),

        id("left_superior_temporal_gyrus"),
        id("left_middle_temporal_gyrus"),
        id("left_inferior_temporal_gyrus"),
        id("left_temporal_lobe"),

        id("left_superior_occipital_gyrus"),
        id("left_middle_occipital_gyrus"),
        id("left_inferior_occipital_gyrus"),
        id("left_occipital_lobe"),

        // === ESTRUCTURAS MEDIAS ===
        id("cerebrum"),
        id("cerebellum"),
        id("brainstem"),
        id("corpus_callosum"),
        id("pons"),
        id("medulla_oblongata"),
        id("midbrain")
    ]

    /// Vasos cerebrales (arteria cerebral, círculo de Willis, seno venoso).
    static let vessels: [String] = [
        id("cerebral_arteries"),
        id("anterior_cerebral_artery"),
        id("middle_cerebral_artery"),
        id("posterior_cerebral_artery"),
        id("circle_of_willis"),
        id("internal_carotid_artery"),
        id("vertebral_artery"),
        id("basilar_artery"),
        id("cerebral_veins"),
        id("blood_vessels")
    ]

    /// Sustancia gris/blanca y núcleos subcorticales (daño por atrofia).
    static let graymatter: [String] = [
        id("gray_matter"),
        id("white_matter"),
        id("cortex"),
        id("cerebral_cortex"),
        id("basal_ganglia"),
        id("thalamus"),
        id("hippocampus"),
        id("amygdala"),
        id("hypothalamus")
    ]
}

struct BrainVisualizer {

    static func apply(damage: Double, on human: AnyObject) {
        #if HAS_HUMANKIT
        guard let human = human as? HKHuman else { return }
        let d = min(max(damage, 0.0), 1.0)

        // 1. Tint general del cerebro
        let tint = brainColor(for: d)
        for objectId in BrainObjectIds.wholeBrain {
            human.scene.color(objectId: objectId, color: tint)
        }

        // 2. Vasos cerebrales se inflaman con damage >0.35
        if d > 0.3 {
            let vesselTint = vesselColor(for: d)
            for objectId in BrainObjectIds.vessels {
                human.scene.color(objectId: objectId, color: vesselTint)
            }
        }

        // 3. Sustancia gris/blanca: atrofia con damage >0.65
        if d > 0.6 {
            let atrophyTint = atrophyColor(for: d)
            for objectId in BrainObjectIds.graymatter {
                human.scene.color(objectId: objectId, color: atrophyTint)
            }
        }
        #endif
    }

    // MARK: - Color curves

    #if HAS_HUMANKIT

    /// Cerebro: rosado-salmón sano → naranja inflamación → rojo daño → púrpura atrofia.
    private static func brainColor(for damage: Double) -> HKColor {
        let c = HKColor()
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.95, green: 0.75, blue: 0.70, alpha: 1)), // salmón sano
            (0.25, UIColor(red: 0.90, green: 0.65, blue: 0.45, alpha: 1)), // durazno / inflamación leve
            (0.50, UIColor(red: 0.95, green: 0.45, blue: 0.30, alpha: 1)), // naranja / inflamación moderada
            (0.75, UIColor(red: 0.75, green: 0.25, blue: 0.30, alpha: 1)), // rojo / daño vascular
            (1.00, UIColor(red: 0.35, green: 0.15, blue: 0.40, alpha: 1))  // púrpura atrofia
        ], t: damage)
        c.opacity = CGFloat(0.65 + damage * 0.25)
        return c
    }

    /// Vasos cerebrales: rojo intenso (hemorragia, microinfartos).
    private static func vesselColor(for damage: Double) -> HKColor {
        let c = HKColor()
        let remapped = (damage - 0.3) / 0.7
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.90, green: 0.35, blue: 0.35, alpha: 1)),
            (1.00, UIColor(red: 0.45, green: 0.08, blue: 0.08, alpha: 1))
        ], t: remapped)
        c.opacity = 0.95
        return c
    }

    /// Sustancia con atrofia (pérdida neuronal).
    private static func atrophyColor(for damage: Double) -> HKColor {
        let c = HKColor()
        let remapped = (damage - 0.6) / 0.4
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.55, green: 0.40, blue: 0.50, alpha: 1)),
            (1.00, UIColor(red: 0.20, green: 0.10, blue: 0.25, alpha: 1))
        ], t: remapped)
        c.opacity = 0.88
        return c
    }

    #endif
}
