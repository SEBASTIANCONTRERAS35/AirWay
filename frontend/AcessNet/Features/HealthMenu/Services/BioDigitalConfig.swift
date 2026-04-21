//
//  BioDigitalConfig.swift
//  AcessNet
//
//  Configuración del SDK BioDigital HumanKit.
//
//  Según la documentación oficial, el SDK lee sus credenciales directamente
//  del archivo `BioDigital.plist` en el bundle (claves `APIKey` y `APISecret`).
//  Este tipo **no** lee credenciales — solo expone utilidades de inspección
//  (¿existe el plist?) y el modelo por default a cargar.
//

import Foundation

enum BioDigitalConfig {

    /// `true` cuando `BioDigital.plist` está incluido en el bundle. Es lo
    /// único que podemos garantizar desde fuera del SDK. Si está presente
    /// pero sus valores son incorrectos, el SDK notificará vía
    /// `HKServicesDelegate.onInvalidSDK()`.
    static var isConfigured: Bool {
        Bundle.main.url(forResource: "BioDigital", withExtension: "plist") != nil
    }

    /// Modelo por defecto a cargar. Usamos el ID corto `3Y78` que aparece
    /// documentado como modelo público/demo en la integración oficial de
    /// ResearchKit de BioDigital. Los paths largos tipo
    /// `production/maleAdult/flu.json` pueden requerir licencias premium.
    // TODO: permitir override por usuario / por estado de salud
    static let defaultModelId = "3Y78"

    /// Fallbacks a probar si el modelo primario falla.
    static let fallbackModelIds: [String] = [
        "production/maleAdult/flu.json",
        "production/maleAdult/heart.json",
        "production/maleAdult/skeleton.json"
    ]

    /// Lectura opcional para debug — útil para imprimir en consola qué keys
    /// quedaron realmente en el plist al runtime.
    static func debugDump() {
        guard let url = Bundle.main.url(forResource: "BioDigital", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any] else {
            print("🩺 [BioDigital.plist] ❌ No se encontró en el bundle")
            return
        }
        print("🩺 [BioDigital.plist] ✅ Encontrado en bundle. Keys:")
        for (k, v) in dict {
            let value = v as? String ?? "(non-string)"
            let masked = value.count > 8 ? "\(value.prefix(8))…" : value
            print("    · \(k) = \(masked)")
        }
    }
}
