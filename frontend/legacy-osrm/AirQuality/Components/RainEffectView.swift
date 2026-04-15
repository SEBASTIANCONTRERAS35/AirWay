//
//  RainEffectView.swift
//  AcessNet
//
//  Created by BICHOTEE
//

import SwiftUI
import Combine

struct RainEffectView: View {
    @State private var raindrops: [Raindrop] = []
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(raindrops) { drop in
                    RaindropView(drop: drop)
                }
            }
            .onAppear {
                generateRaindrops(in: geometry.size)
            }
            .onReceive(timer) { _ in
                updateRaindrops()
            }
        }
        .ignoresSafeArea()
    }

    private func generateRaindrops(in size: CGSize) {
        raindrops = (0..<30).map { _ in
            Raindrop(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -size.height...0),
                speed: CGFloat.random(in: 3...6),
                length: CGFloat.random(in: 15...30),
                opacity: Double.random(in: 0.2...0.5)
            )
        }
    }

    private func updateRaindrops() {
        for index in raindrops.indices {
            raindrops[index].y += raindrops[index].speed

            if raindrops[index].y > UIScreen.main.bounds.height {
                raindrops[index].y = -raindrops[index].length
                raindrops[index].x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            }
        }
    }
}

struct Raindrop: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let speed: CGFloat
    let length: CGFloat
    let opacity: Double
}

struct RaindropView: View {
    let drop: Raindrop

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(drop.opacity),
                        .white.opacity(drop.opacity * 0.5),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: drop.length)
            .rotationEffect(.degrees(10))
            .position(x: drop.x, y: drop.y)
    }
}

#Preview {
    ZStack {
        Color(hex: "#FFD54F")
            .ignoresSafeArea()
        RainEffectView()
    }
}

