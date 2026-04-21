//
//  ColorLerp.swift
//  AcessNet
//
//  Interpolación lineal entre stops de color a partir de un valor t ∈ [0, 1].
//  Compartido por HeartVisualizer, LungVisualizer y BrainVisualizer.
//

import Foundation
import UIKit

enum ColorLerp {

    /// Interpola entre una lista de stops `(t, UIColor)` ordenados por t.
    static func interpolate(_ stops: [(t: Double, color: UIColor)], t: Double) -> UIColor {
        let clamped = min(max(t, 0.0), 1.0)

        guard let upperIdx = stops.firstIndex(where: { $0.t >= clamped }) else {
            return stops.last!.color
        }
        if upperIdx == 0 { return stops[0].color }

        let lower = stops[upperIdx - 1]
        let upper = stops[upperIdx]
        let span = upper.t - lower.t
        let local = span > 0 ? (clamped - lower.t) / span : 0

        return blend(lower.color, upper.color, t: local)
    }

    /// Mezcla dos UIColor por un factor t ∈ [0, 1] en el espacio RGB.
    static func blend(_ a: UIColor, _ b: UIColor, t: Double) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let tf = CGFloat(t)
        return UIColor(
            red:   r1 + (r2 - r1) * tf,
            green: g1 + (g2 - g1) * tf,
            blue:  b1 + (b2 - b1) * tf,
            alpha: a1 + (a2 - a1) * tf
        )
    }
}
