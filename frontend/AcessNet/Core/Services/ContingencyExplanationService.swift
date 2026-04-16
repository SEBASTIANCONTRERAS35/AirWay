//
//  ContingencyExplanationService.swift
//  AcessNet
//
//  Usa Apple Intelligence Foundation Models (iOS 26+) para generar
//  una explicación en español simple de la probabilidad de contingencia.
//
//  Privacidad: el modelo corre ON-DEVICE. Nada de los features del
//  usuario sale del iPhone. Cero costo por token.
//

import Foundation
import FoundationModels

// MARK: - Structured output

/// Output estructurado que queremos del modelo on-device.
@Generable
struct ContingencyNaturalExplanation {
    @Guide(description: "Explicación en 1-2 oraciones, nivel primaria, en español mexicano. NUNCA usar certezas absolutas — usa 'probabilidad', 'el modelo estima', 'podría'. Menciona los 2 factores más importantes.")
    let mainText: String

    @Guide(description: "Tono emocional de la explicación: tranquilo, alerta o precaución.")
    let tone: ExplanationTone

    @Guide(description: "Un tip concreto y corto (10-15 palabras) para el usuario.")
    let quickTip: String
}

@Generable
enum ExplanationTone: String {
    case tranquilo
    case precaucion
    case alerta
}

// MARK: - Service

@MainActor
final class ContingencyExplanationService {

    static let shared = ContingencyExplanationService()

    private init() {}

    /// Genera una explicación natural a partir del pronóstico y hint del backend.
    /// Si Foundation Models falla o no está disponible, devuelve un fallback estático.
    func explain(
        forecast: HorizonForecast,
        hint: String
    ) async -> String {

        // Compone prompt con los drivers reales para grounding
        let driversDescription = forecast.topDrivers.prefix(3).map { driver in
            if let value = driver.value {
                return "\(driver.humanName) = \(String(format: "%.1f", value))"
            }
            return driver.humanName
        }.joined(separator: ", ")

        let userPrompt = """
        Pronóstico:
        - Probabilidad Fase 1 Ozono en \(forecast.horizonH) horas: \(forecast.probabilityPercent)%
        - Ozono esperado: \(Int(round(forecast.o3ExpectedPpb))) ppb (umbral contingencia: 154)
        - Drivers principales: \(driversDescription)
        - Hint: \(hint)

        Explica en español simple por qué el modelo estima esta probabilidad.
        Enfócate en los drivers. Máximo 2 oraciones.
        """

        do {
            let session = LanguageModelSession(instructions: """
                Eres un meteorólogo experto en calidad del aire en la Ciudad de México.
                Hablas a una persona sin estudios técnicos.
                Usa español mexicano claro, nivel primaria.
                NUNCA afirmes certezas absolutas — usa "probabilidad", "el modelo estima", "podría".
                No uses jerga técnica (no "PPB", no "µg/m³", no "capa de mezcla").
                Prefiere palabras como: "calor", "viento", "polvo", "humo", "lluvia".
                Máximo 2 oraciones. Tono empático y útil.
            """)

            let result = try await session.respond(
                to: userPrompt,
                generating: ContingencyNaturalExplanation.self
            )

            return result.content.mainText
        } catch {
            print("[Foundation Models] error: \(error.localizedDescription). Usando fallback.")
            return fallbackExplanation(for: forecast)
        }
    }

    /// Explicación estática usada cuando Foundation Models no está disponible.
    private func fallbackExplanation(for forecast: HorizonForecast) -> String {
        let pct = forecast.probabilityPercent
        let driverName = forecast.topDrivers.first?.humanName ?? "varios factores meteorológicos"

        switch forecast.probabilityLevel {
        case .low:
            return "El modelo estima una probabilidad baja (\(pct)%) de contingencia en las próximas \(forecast.horizonH) horas. Las condiciones se ven estables."
        case .moderate:
            return "Probabilidad moderada (\(pct)%) de que se active contingencia. El factor más relevante hoy es \(driverName.lowercased()). Mantente pendiente."
        case .high:
            return "Probabilidad alta (\(pct)%) de contingencia en \(forecast.horizonH) horas por \(driverName.lowercased()). Conviene preparar plan B para el transporte y limitar ejercicio al aire libre."
        case .veryHigh:
            return "Probabilidad muy alta (\(pct)%) de Fase 1 en \(forecast.horizonH) horas. Espera restricciones de circulación y efectos respiratorios — toma precauciones hoy mismo."
        }
    }
}
