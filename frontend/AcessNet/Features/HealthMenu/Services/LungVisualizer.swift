//
//  LungVisualizer.swift
//  AcessNet
//
//  Aplica deterioro visual progresivo a UN solo modelo de pulmones de BioDigital.
//  Mismo approach que HeartVisualizer pero con paleta e IDs específicos del
//  modelo `production/maleAdult/asthma_v02` (pulmón con bronquios y tráquea).
//
//  NOTA: los IDs candidatos siguen el patrón aprendido en el corazón
//  (`bd_normal_heart_glass-*_1338_ID`). Si al probar no se tiñen, toca la parte
//  correspondiente en la app y copia el `objectPicked` real para ajustar.
//

import Foundation
import UIKit

#if HAS_HUMANKIT
import HumanKit
#endif

enum LungObjectIds {
    /// Patrón confirmado vía objectPicked: `bd_asthma-{part}_ID`
    /// (sin `_glass`, sin sufijo numérico — diferente al corazón).

    private static let prefix = "bd_asthma-"
    private static let suffix = "_ID"

    private static func id(_ part: String) -> String {
        "\(prefix)\(part)\(suffix)"
    }

    /// Lóbulos pulmonares completos.
    static let wholeLungs: [String] = [
        // Pulmón izquierdo (2 lóbulos)
        id("left_superior_lobe"),
        id("left_inferior_lobe"),
        id("left_lung"),

        // Pulmón derecho (3 lóbulos)
        id("right_superior_lobe"),
        id("right_middle_lobe"),
        id("right_inferior_lobe"),
        id("right_lung"),

        // Parénquima / pleura
        id("pleura"),
        id("visceral_pleura"),
        id("parietal_pleura"),

        // Fisuras
        id("oblique_fissure"),
        id("horizontal_fissure"),

        // Diafragma (si está en el modelo)
        id("diaphragm")
    ]

    /// Tráquea, bronquios y ramificaciones (vía aérea).
    static let bronchi: [String] = [
        id("trachea"),
        id("larynx"),
        id("pharynx"),

        // Bronquios principales
        id("left_main_bronchus"),
        id("right_main_bronchus"),
        id("main_bronchi"),
        id("bronchi"),

        // Bronquios lobares
        id("left_superior_lobar_bronchus"),
        id("left_inferior_lobar_bronchus"),
        id("right_superior_lobar_bronchus"),
        id("right_middle_lobar_bronchus"),
        id("right_inferior_lobar_bronchus"),

        // Segmentales
        id("segmental_bronchi"),
        id("bronchial_tree")
    ]

    /// Alvéolos, bronquiolos, vasculatura.
    static let alveoli: [String] = [
        id("alveoli"),
        id("alveolus"),
        id("bronchioles"),
        id("terminal_bronchioles"),
        id("respiratory_bronchioles"),
        id("alveolar_ducts"),
        id("alveolar_sacs"),

        // Vasculatura pulmonar
        id("pulmonary_arteries"),
        id("pulmonary_veins"),
        id("pulmonary_capillaries")
    ]
}

struct LungVisualizer {

    static func apply(damage: Double, on human: AnyObject) {
        #if HAS_HUMANKIT
        guard let human = human as? HKHuman else { return }
        let d = min(max(damage, 0.0), 1.0)

        // 1. Tint general: rosado sano → amarillo → marrón alquitrán (fumador) → gris oscuro
        let tint = lungColor(for: d)
        for objectId in LungObjectIds.wholeLungs {
            human.scene.color(objectId: objectId, color: tint)
        }

        // 2. Bronquios / tráquea se inflaman (rojo) con damage >0.35
        if d > 0.3 {
            let bronchiTint = bronchiColor(for: d)
            for objectId in LungObjectIds.bronchi {
                human.scene.color(objectId: objectId, color: bronchiTint)
            }
        }

        // 3. Alvéolos colapsados (gris oscuro) con damage >0.60
        if d > 0.55 {
            let alveoliTint = alveoliColor(for: d)
            for objectId in LungObjectIds.alveoli {
                human.scene.color(objectId: objectId, color: alveoliTint)
            }
        }
        #endif
    }

    // MARK: - Color curves

    #if HAS_HUMANKIT

    /// Pulmón: rosado sano → amarillento (nicotina/PM2.5) → marrón → casi negro.
    private static func lungColor(for damage: Double) -> HKColor {
        let c = HKColor()
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.95, green: 0.75, blue: 0.75, alpha: 1)), // rosado sano
            (0.25, UIColor(red: 0.85, green: 0.75, blue: 0.50, alpha: 1)), // amarillento
            (0.50, UIColor(red: 0.70, green: 0.55, blue: 0.35, alpha: 1)), // marrón claro
            (0.75, UIColor(red: 0.40, green: 0.30, blue: 0.20, alpha: 1)), // marrón oscuro
            (1.00, UIColor(red: 0.15, green: 0.10, blue: 0.10, alpha: 1))  // casi negro
        ], t: damage)
        c.opacity = CGFloat(0.60 + damage * 0.30)
        return c
    }

    /// Bronquios inflamados: rojo intenso progresivo.
    private static func bronchiColor(for damage: Double) -> HKColor {
        let c = HKColor()
        let remapped = (damage - 0.3) / 0.7
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.95, green: 0.40, blue: 0.40, alpha: 1)),
            (0.50, UIColor(red: 0.80, green: 0.20, blue: 0.20, alpha: 1)),
            (1.00, UIColor(red: 0.45, green: 0.10, blue: 0.10, alpha: 1))
        ], t: remapped)
        c.opacity = 0.95
        return c
    }

    /// Alvéolos destruidos: gris oscuro, tejido cicatrizado.
    private static func alveoliColor(for damage: Double) -> HKColor {
        let c = HKColor()
        let remapped = (damage - 0.55) / 0.45
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.55, green: 0.45, blue: 0.40, alpha: 1)),
            (1.00, UIColor(red: 0.15, green: 0.12, blue: 0.12, alpha: 1))
        ], t: remapped)
        c.opacity = 0.90
        return c
    }

    #endif
}
