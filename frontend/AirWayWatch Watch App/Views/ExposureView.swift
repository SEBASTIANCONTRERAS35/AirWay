//
//  ExposureView.swift
//  AirWayWatch Watch App
//
//  Created by BICHOTEE
//

import SwiftUI

struct ExposureView: View {
    let homeHours: CGFloat = 6
    let workHours: CGFloat = 4
    let outdoorHours: CGFloat = 3

    var totalHours: CGFloat {
        homeHours + workHours + outdoorHours
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Today's Exposure")
                    .font(.headline)
                    .foregroundColor(.white)

                // Circular exposure chart
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 20)
                        .frame(width: 120, height: 120)

                    // Home segment (Yellow)
                    Circle()
                        .trim(from: 0, to: homeHours / 24)
                        .stroke(
                            Color(hex: "#FFD54F"),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    // Work segment (Green)
                    Circle()
                        .trim(from: homeHours / 24, to: (homeHours + workHours) / 24)
                        .stroke(
                            Color(hex: "#81C784"),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    // Outdoor segment (Orange)
                    Circle()
                        .trim(from: (homeHours + workHours) / 24, to: totalHours / 24)
                        .stroke(
                            Color(hex: "#FFA726"),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    // Center text
                    VStack(spacing: 2) {
                        Text("\(Int(totalHours))h")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Legend
                VStack(spacing: 8) {
                    ExposureLegendRow(
                        color: Color(hex: "#FFD54F"),
                        label: "Home",
                        hours: Int(homeHours)
                    )

                    ExposureLegendRow(
                        color: Color(hex: "#81C784"),
                        label: "Work",
                        hours: Int(workHours)
                    )

                    ExposureLegendRow(
                        color: Color(hex: "#FFA726"),
                        label: "Outdoor",
                        hours: Int(outdoorHours)
                    )
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "#0A1D4D"),
                    Color(hex: "#4AA1B3")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

struct ExposureLegendRow: View {
    let color: Color
    let label: String
    let hours: Int

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text("\(hours)h")
                .font(.caption2.bold())
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ExposureView()
}
