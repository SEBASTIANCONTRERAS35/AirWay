//
//  MascotCharacter.swift
//  AcessNet
//
//  Created by BICHOTEE
//

import SwiftUI

struct MascotCharacter: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Head
            ZStack {
                // Face
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFE0B2"), Color(hex: "#FFCC80")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 60)

                // Hair
                HStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "#5D4037"))
                            .frame(width: 8, height: 15)
                    }
                }
                .offset(x: 10, y: -25)
                .rotationEffect(.degrees(-10))

                // Eyes
                HStack(spacing: 12) {
                    // Left eye
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 14, height: 14)

                        Circle()
                            .fill(Color(hex: "#3E2723"))
                            .frame(width: 8, height: 8)
                            .offset(x: 2)
                    }

                    // Right eye
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 14, height: 14)

                        Circle()
                            .fill(Color(hex: "#3E2723"))
                            .frame(width: 8, height: 8)
                            .offset(x: 2)
                    }
                }
                .offset(y: -5)

                // Worried expression lines
                HStack(spacing: 8) {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 6, y: -2))
                    }
                    .stroke(Color(hex: "#5D4037"), lineWidth: 2)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: -2))
                        path.addLine(to: CGPoint(x: 6, y: 0))
                    }
                    .stroke(Color(hex: "#5D4037"), lineWidth: 2)
                }
                .offset(x: 25, y: -10)

                // Mouth (worried)
                Path { path in
                    path.move(to: CGPoint(x: -8, y: 15))
                    path.addQuadCurve(
                        to: CGPoint(x: 8, y: 15),
                        control: CGPoint(x: 0, y: 12)
                    )
                }
                .stroke(Color(hex: "#5D4037"), lineWidth: 2)
            }

            // Body
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#FDD835"))
                .frame(width: 50, height: 70)
                .overlay(
                    VStack {
                        // Zipper
                        Rectangle()
                            .fill(Color(hex: "#F9A825"))
                            .frame(width: 3, height: 40)

                        Circle()
                            .fill(Color(hex: "#F9A825"))
                            .frame(width: 8, height: 8)
                    }
                )
                .offset(y: -10)

            // Legs
            HStack(spacing: 10) {
                // Left leg
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#8D6E63"))
                    .frame(width: 15, height: 30)

                // Right leg
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#8D6E63"))
                    .frame(width: 15, height: 30)
            }
            .offset(y: -10)

            // Shoes
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: "#3E2723"))
                    .frame(width: 20, height: 10)

                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: "#3E2723"))
                    .frame(width: 20, height: 10)
            }
            .offset(y: -10)
        }
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .animation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#FFD54F")
            .ignoresSafeArea()

        MascotCharacter()
    }
}
