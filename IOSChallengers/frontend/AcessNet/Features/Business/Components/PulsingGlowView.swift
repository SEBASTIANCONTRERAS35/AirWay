//
//  PulsingGlowView.swift
//  AcessNet
//
//  Created to provide an animated glow used in SideMenuView.
//

import SwiftUI

struct PulsingGlowView: View {
    // The base color for the glow
    var color: Color = .blue
    @State private var animate = false

    var body: some View {
        ZStack {
            // Soft blurred fill to simulate glow
            Circle()
                .fill(color.opacity(0.25))
                .scaleEffect(animate ? 1.4 : 0.8)
                .blur(radius: 8)

            // Outer ring that fades out as it expands
            Circle()
                .stroke(color.opacity(0.9), lineWidth: 2)
                .scaleEffect(animate ? 1.2 : 1.0)
                .opacity(animate ? 0.0 : 1.0)
        }
        .animation(
            .easeOut(duration: 1.2)
                .repeatForever(autoreverses: true),
            value: animate
        )
        .onAppear { animate = true }
    }
}

#Preview {
    PulsingGlowView(color: .blue)
        .frame(width: 60, height: 60)
}
