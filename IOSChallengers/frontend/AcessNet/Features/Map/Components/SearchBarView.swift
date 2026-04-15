//
//  SearchBarView.swift
//  AcessNet
//
//  Barra de búsqueda refactorizada con soporte para focus y callbacks
//

import SwiftUI

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var searchText: String
    @FocusState.Binding var isFocused: Bool

    let placeholder: String
    let onSubmit: () -> Void
    let onClear: () -> Void

    init(
        searchText: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        placeholder: String = "Where to?",
        onSubmit: @escaping () -> Void = {},
        onClear: @escaping () -> Void = {}
    ) {
        self._searchText = searchText
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.onSubmit = onSubmit
        self.onClear = onClear
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icono de búsqueda con animación
                ZStack {
                    Circle()
                        .fill(isFocused ? Color.blue.opacity(0.12) : Color.clear)
                        .frame(width: 32, height: 32)

                    Image(systemName: isFocused ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        .font(.system(size: 18, weight: isFocused ? .semibold : .regular))
                        .foregroundStyle(
                            isFocused ?
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.gray, .gray.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)

                // Campo de texto
                TextField(placeholder, text: $searchText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onSubmit()
                    }
                    .autocorrectionDisabled()
                    .onChange(of: isFocused) { newValue in
                        if newValue {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }

                // Botón de limpiar con animación mejorada
                if !searchText.isEmpty {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchText = ""
                            onClear()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 24, height: 24)

                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Botón de cancelar cuando está enfocado
                if isFocused {
                    Button("Cancel") {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchText = ""
                            isFocused = false
                            onClear()
                        }
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, isFocused ? 18 : 16)
            .padding(.vertical, isFocused ? 14 : 12)
            .background(
                ZStack {
                    // Fondo con blur
                    RoundedRectangle(cornerRadius: isFocused ? 28 : 25)
                        .fill(.ultraThinMaterial)

                    // Overlay de gradiente sutil
                    RoundedRectangle(cornerRadius: isFocused ? 28 : 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(isFocused ? 0.15 : 0.1),
                                    .white.opacity(isFocused ? 0.05 : 0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Borde con gradiente
                    RoundedRectangle(cornerRadius: isFocused ? 28 : 25)
                        .strokeBorder(
                            LinearGradient(
                                colors: isFocused ?
                                [Color.blue.opacity(0.4), Color.blue.opacity(0.2)] :
                                [Color.gray.opacity(0.15), Color.gray.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 2 : 1
                        )
                }
            )
            .shadow(
                color: isFocused ? Color.blue.opacity(0.15) : .black.opacity(0.12),
                radius: isFocused ? 20 : 15,
                x: 0,
                y: isFocused ? 8 : 5
            )
            .shadow(
                color: .black.opacity(0.08),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - Compact Search Bar (para cuando hay poco espacio)

struct CompactSearchBar: View {
    @Binding var searchText: String
    @FocusState.Binding var isFocused: Bool

    let onTap: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onTap()
                isFocused = true
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                Text(searchText.isEmpty ? "Search" : searchText)
                    .font(.system(size: 15))
                    .foregroundColor(searchText.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
        }
    }
}

// MARK: - Search Bar with Voice (futuro)

struct SearchBarWithVoice: View {
    @Binding var searchText: String
    @FocusState.Binding var isFocused: Bool

    let placeholder: String
    let onVoiceSearch: () -> Void
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icono de búsqueda
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(isFocused ? .blue : .gray)

            // Campo de texto
            TextField(placeholder, text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit(onSubmit)

            // Botón de limpiar o micrófono
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onClear()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .transition(.scale)
            } else {
                Button(action: onVoiceSearch) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.blue)
                }
                .transition(.scale)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
    }
}

// MARK: - Preview

#Preview("Standard Search Bar") {
    struct PreviewWrapper: View {
        @State private var searchText = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack(spacing: 20) {
                SearchBarView(
                    searchText: $searchText,
                    isFocused: $isFocused,
                    placeholder: "Where to?",
                    onSubmit: {
                        print("Submit: \(searchText)")
                    },
                    onClear: {
                        print("Cleared")
                    }
                )
                .padding()

                Text("Focused: \(isFocused ? "Yes" : "No")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Toggle Focus") {
                    isFocused.toggle()
                }

                Spacer()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Compact Search Bar") {
    struct PreviewWrapper: View {
        @State private var searchText = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                CompactSearchBar(
                    searchText: $searchText,
                    isFocused: $isFocused,
                    onTap: {
                        print("Tapped")
                    }
                )
                .padding()

                Spacer()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("With Voice") {
    struct PreviewWrapper: View {
        @State private var searchText = "Starbucks"
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                SearchBarWithVoice(
                    searchText: $searchText,
                    isFocused: $isFocused,
                    placeholder: "Search places...",
                    onVoiceSearch: {
                        print("Voice search")
                    },
                    onSubmit: {
                        print("Submit: \(searchText)")
                    },
                    onClear: {
                        print("Cleared")
                    }
                )
                .padding()

                Spacer()
            }
        }
    }

    return PreviewWrapper()
}
