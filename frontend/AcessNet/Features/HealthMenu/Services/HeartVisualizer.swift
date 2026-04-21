//
//  HeartVisualizer.swift
//  AcessNet
//
//  Aplica deterioro visual progresivo a UN solo modelo de corazón de BioDigital
//  en vez de cambiar entre modelos discretos. La entrada es un `damageLevel`
//  continuo (0.0 = sano · 1.0 = terminal) y se traduce a:
//    · Color interpolado verde → amarillo → naranja → rojo oscuro
//    · Opacidad creciente (tejido más "denso" cuando hay inflamación)
//    · Tint adicional a arterias coronarias si el SDK las expone
//
//  El usuario ve una transición SUAVE dentro del mismo corazón en vez de
//  saltar entre 5 modelos diferentes.
//

import Foundation
import UIKit

#if HAS_HUMANKIT
import HumanKit
#endif

/// Nombre de objetos candidatos dentro del modelo `normal_heart_conduction_system`.
/// BioDigital usa convenciones tipo `bd_beating_heart-{part}_1337_ID` pero no
/// las documenta públicamente. Probamos varios y pintamos los que existan
/// (el SDK ignora silenciosamente los IDs no encontrados).
enum HeartObjectIds {
    /// Patrón real confirmado vía objectPicked: `bd_normal_heart_glass-{part}_1338_ID`
    /// El `1338` es constante para el modelo `production/maleAdult/normal_heart_conduction_system`.
    /// Si cargas otro modelo, los IDs cambiarán y hay que volver a descubrirlos.

    private static let prefix = "bd_normal_heart_glass-"
    private static let suffix = "_1338_ID"

    private static func id(_ part: String) -> String {
        "\(prefix)\(part)\(suffix)"
    }

    /// Partes del corazón completo — cubren ventrículos, atrios, grandes vasos.
    /// Cada parte es un sub-objeto separado en el modelo 3D.
    static let wholeHeart: [String] = [
        // Ventrículos (4 caras: exterior/interior para cada lado)
        id("left_ventricle_exterior"),
        id("left_ventricle_interior"),
        id("left_ventricle_interior1"),
        id("left_ventricle_interior2"),
        id("right_ventricle_exterior"),
        id("right_ventricle_interior"),
        id("right_ventricle_interior1"),
        id("right_ventricle_interior2"),

        // Atrios
        id("left_atrium_exterior"),
        id("left_atrium_interior"),
        id("right_atrium_exterior"),
        id("right_atrium_interior"),

        // Septum
        id("interventricular_septum"),
        id("interatrial_septum"),
        id("septum"),

        // Grandes vasos
        id("aorta"),
        id("ascending_aorta"),
        id("aortic_arch"),
        id("pulmonary_trunk"),
        id("pulmonary_artery"),
        id("superior_vena_cava"),
        id("inferior_vena_cava"),
        id("pulmonary_veins"),

        // Apex / pared general
        id("heart"),
        id("apex"),
        id("pericardium"),
        id("epicardium")
    ]

    /// Arterias coronarias específicas.
    static let coronaryArteries: [String] = [
        id("coronary_arteries"),
        id("right_coronary_artery"),
        id("left_coronary_artery"),
        id("left_main_coronary_artery"),
        id("anterior_interventricular_branch_of_left_coronary_artery"),
        id("circumflex_branch_of_left_coronary_artery"),
        id("posterior_interventricular_branch_of_right_coronary_artery"),
        id("marginal_branch_of_right_coronary_artery")
    ]

    /// Músculo cardíaco (miocardio) y elementos internos.
    static let myocardium: [String] = [
        id("myocardium"),
        id("cardiac_muscle"),
        id("left_ventricular_wall"),
        id("right_ventricular_wall"),
        id("papillary_muscles"),
        id("chordae_tendineae"),
        id("trabeculae_carneae")
    ]

    /// Válvulas (útil para etapas severas).
    static let valves: [String] = [
        id("aortic_valve"),
        id("mitral_valve"),
        id("tricuspid_valve"),
        id("pulmonary_valve")
    ]
}

struct HeartVisualizer {

    /// Aplica el efecto visual al corazón basado en el damageLevel (0.0-1.0).
    /// Llamar DESPUÉS de que el modelo terminó de cargar.
    static func apply(damage: Double, on human: AnyObject) {
        #if HAS_HUMANKIT
        guard let human = human as? HKHuman else { return }

        let d = min(max(damage, 0.0), 1.0)

        // 1. Tint principal al corazón completo
        let heartTint = heartColor(for: d)
        for objectId in HeartObjectIds.wholeHeart {
            human.scene.color(objectId: objectId, color: heartTint)
        }

        // 2. Arterias coronarias: desde damage 0.3
        if d > 0.3 {
            let arteryTint = arteryColor(for: d)
            for objectId in HeartObjectIds.coronaryArteries {
                human.scene.color(objectId: objectId, color: arteryTint)
            }
        }

        // 3. Miocardio: desde damage 0.6
        if d > 0.6 {
            let necrosisTint = necrosisColor(for: d)
            for objectId in HeartObjectIds.myocardium {
                human.scene.color(objectId: objectId, color: necrosisTint)
            }
        }

        // 4. Válvulas también se tintan en etapa crítica
        if d > 0.75 {
            let necrosisTint = necrosisColor(for: d)
            for objectId in HeartObjectIds.valves {
                human.scene.color(objectId: objectId, color: necrosisTint)
            }
        }
        #endif
    }

    // MARK: - Color curves

    #if HAS_HUMANKIT

    /// Color principal del corazón: verde suave → amarillo → naranja → rojo oscuro.
    private static func heartColor(for damage: Double) -> HKColor {
        let c = HKColor()
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.45, green: 0.85, blue: 0.55, alpha: 1)), // verde sano
            (0.25, UIColor(red: 0.85, green: 0.85, blue: 0.45, alpha: 1)), // amarillo
            (0.50, UIColor(red: 1.00, green: 0.60, blue: 0.25, alpha: 1)), // naranja
            (0.75, UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)), // rojo
            (1.00, UIColor(red: 0.50, green: 0.08, blue: 0.08, alpha: 1))  // rojo oscuro terminal
        ], t: damage)
        c.opacity = CGFloat(0.65 + damage * 0.25) // más opaco cuando hay daño (inflamación)
        return c
    }

    /// Color de arterias coronarias: rojo brillante → rojo oscuro sangre coagulada.
    private static func arteryColor(for damage: Double) -> HKColor {
        let c = HKColor()
        let remapped = (damage - 0.3) / 0.7 // normalizar 0.3-1.0 → 0-1
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)),
            (0.50, UIColor(red: 0.75, green: 0.15, blue: 0.15, alpha: 1)),
            (1.00, UIColor(red: 0.35, green: 0.05, blue: 0.05, alpha: 1))
        ], t: remapped)
        c.opacity = 0.95
        return c
    }

    /// Color de miocardio con zonas necróticas.
    private static func necrosisColor(for damage: Double) -> HKColor {
        let c = HKColor()
        let remapped = (damage - 0.6) / 0.4
        c.tint = ColorLerp.interpolate([
            (0.00, UIColor(red: 0.60, green: 0.20, blue: 0.20, alpha: 1)),
            (1.00, UIColor(red: 0.20, green: 0.05, blue: 0.05, alpha: 1))
        ], t: remapped)
        c.opacity = 0.90
        return c
    }

    #endif
}
