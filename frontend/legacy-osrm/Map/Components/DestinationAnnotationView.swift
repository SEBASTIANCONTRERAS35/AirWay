//
//  DestinationAnnotationView.swift
//  AcessNet
//
//  Vista de anotación para el punto de destino (Punto B)
//

import SwiftUI
import MapKit

// MARK: - Destination Annotation View

struct DestinationAnnotationView: View {
    @State private var animate = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Pulso de fondo
            Circle()
                .stroke(Color.green, lineWidth: 3)
                .scaleEffect(pulse ? 2.0 : 1.0)
                .opacity(pulse ? 0.0 : 0.6)
                .frame(width: 50, height: 50)

            // Pin principal
            VStack(spacing: 0) {
                // Círculo superior
                ZStack {
                    // Gradiente de fondo
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 45, height: 45)
                        .shadow(color: .green.opacity(0.5), radius: 8, x: 0, y: 4)

                    // Borde blanco
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 45, height: 45)

                    // Icono de bandera checkered
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                // Punta del pin
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 10)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            }
            .scaleEffect(animate ? 1.0 : 0.8)
            .offset(y: -22) // Ajustar para que la punta esté en la coordenada exacta
        }
        .onAppear {
            // Animación de aparición con bounce
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                animate = true
            }

            // Animación de pulso continua
            withAnimation(
                .easeOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                pulse = true
            }
        }
    }
}

// MARK: - Compact Destination View

/// Vista compacta del destino para cuando está lejos
struct CompactDestinationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 35, height: 35)
                .shadow(radius: 3)

            Image(systemName: "flag.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Destination Card View

/// Vista expandida con información del destino
struct DestinationCardView: View {
    let title: String
    let subtitle: String?
    let distance: String?
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Icono principal
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(radius: 5)

                Circle()
                    .strokeBorder(.white, lineWidth: 2)
                    .frame(width: 50, height: 50)

                Image(systemName: "flag.checkered.2.crossed")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Info card
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let distance = distance {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        Text(distance)
                            .font(.caption2)
                    }
                    .foregroundStyle(.green)
                }

                // Botón para remover
                Button(action: onRemove) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                        Text("Remove")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.red.opacity(0.1))
                    )
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 3)
            )

            // Pointer (flecha hacia abajo)
            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 6)
                .offset(y: -6)
        }
    }
}

// MARK: - Destination Marker Style

/// Diferentes estilos de marcador de destino
enum DestinationMarkerStyle {
    case flag
    case pin
    case star
    case checkered

    var icon: String {
        switch self {
        case .flag:
            return "flag.fill"
        case .pin:
            return "mappin.circle.fill"
        case .star:
            return "star.fill"
        case .checkered:
            return "flag.checkered.2.crossed"
        }
    }
}

// MARK: - Preview

#Preview("Destination Views") {
    ScrollView {
        VStack(spacing: 40) {
            Text("Destination Annotation Styles")
                .font(.title2.bold())
                .padding(.top, 20)

            // Standard destination view
            VStack {
                DestinationAnnotationView()
                Text("Standard Destination")
                    .font(.caption)
            }

            Divider()

            // Compact view
            VStack {
                CompactDestinationView()
                Text("Compact Destination")
                    .font(.caption)
            }

            Divider()

            // Card view
            DestinationCardView(
                title: "My Destination",
                subtitle: "Selected location",
                distance: "2.5 km away",
                onRemove: { print("Remove tapped") }
            )
        }
        .padding()
    }
}
