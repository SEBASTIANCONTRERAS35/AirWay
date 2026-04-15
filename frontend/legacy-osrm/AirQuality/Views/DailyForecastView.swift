//
//  DailyForecastView.swift
//  AcessNet
//
//  Created by BICHOTEE
//

import SwiftUI

struct DailyForecastView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDay: DailyForecast = DailyForecast.selected
    @State private var selectedTab: ForecastPeriod = .day
    @State private var hourlyData: [HourlyAQIData] = HourlyAQIData.generateSampleDay()

    let weekDays = DailyForecast.sampleWeek

    enum ForecastPeriod {
        case day
        case month
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "#0D1B3E"),
                    Color(hex: "#1A2847"),
                    Color(hex: "#0D1B3E")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with tabs
                    headerView

                    // Day selector
                    daySelector

                    // Main card with AQI info
                    mainAQICard

                    // Hourly chart
                    hourlyChart

                    // Tips by category
                    tipsSection

                    // Weather section
                    weatherSection

                    // More info section
                    moreInfoSection

                    Spacer(minLength: 100)
                }
                .padding(.top, 80)
            }

            // Back button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial.opacity(0.5))
                            )
                    }
                    .padding(.leading)
                    .padding(.top, 50)

                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - View Components

    private var headerView: some View {
        VStack(spacing: 16) {
            // Tabs
            HStack(spacing: 0) {
                TabButton(title: "DAY", isSelected: selectedTab == .day) {
                    selectedTab = .day
                }

                TabButton(title: "MONTH", isSelected: selectedTab == .month) {
                    selectedTab = .month
                }
            }
            .frame(maxWidth: 300)
        }
    }

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(weekDays) { day in
                    DayButton(
                        day: day,
                        isSelected: selectedDay.id == day.id
                    ) {
                        withAnimation(.spring()) {
                            selectedDay = day
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var mainAQICard: some View {
        VStack(spacing: 20) {
            // Location and level
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)

                    Text("TLALPAN")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

                Text("High")
                    .font(.title.bold())
                    .foregroundColor(.white)
            }

            // Main AQI with circular indicator
            HStack(alignment: .top, spacing: 40) {
                // Left side - metrics
                VStack(alignment: .leading, spacing: 20) {
                    MetricItem(label: "AQI", value: "\(selectedDay.aqi)")
                    MetricItem(label: "NO2", value: "\(selectedDay.no2)")
                    MetricItem(label: "PM2.5", value: "\(selectedDay.pm25)")
                    MetricItem(label: "PM10", value: "\(selectedDay.pm10)")
                    MetricItem(label: "O3", value: "\(selectedDay.o3)")
                }

                Spacer()

                // Right side - circular gauge
                CircularAQIGauge(aqi: selectedDay.aqi)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("Secondary").opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal)
    }

    private var hourlyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current time indicator
            Text(currentTimeString())
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

            // Bar chart
            AQIBarChart(data: hourlyData, selectedTime: currentTimeString())
                .frame(height: 200)
                .padding(.horizontal)
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TIPS BY CATEGORY")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            Text("Tap to learn more")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(TipCategory.sampleCategories) { category in
                        TipCategoryCard(category: category)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WEATHER")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            Text("Hourly averages")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)

            HStack(spacing: 0) {
                WeatherMetric(
                    icon: "cloud.rain.fill",
                    value: "\(selectedDay.temperature)",
                    unit: "C°"
                )

                Divider()
                    .frame(height: 60)
                    .background(.white.opacity(0.2))

                WeatherMetric(
                    icon: "wind",
                    value: "\(selectedDay.windSpeed)",
                    unit: "km/h"
                )

                Divider()
                    .frame(height: 60)
                    .background(.white.opacity(0.2))

                WeatherMetric(
                    icon: "umbrella.fill",
                    value: "\(selectedDay.uvIndex)",
                    unit: "UV"
                )

                Divider()
                    .frame(height: 60)
                    .background(.white.opacity(0.2))

                WeatherMetric(
                    icon: "drop.fill",
                    value: "\(selectedDay.humidity)",
                    unit: "% Hum."
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("Secondary").opacity(0.6))
            )
            .padding(.horizontal)
        }
    }

    private var moreInfoSection: some View {
        VStack(spacing: 0) {
            Text("MORE INFO")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 16)

            VStack(spacing: 0) {
                InfoRow(label: "Best day of the year", value: "37 AQI")
                Divider().background(.white.opacity(0.1))
                InfoRow(label: "Annual average", value: "63 AQI")
                Divider().background(.white.opacity(0.1))
                InfoRow(label: "Worst peak of the year", value: "99 AQI")
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("Secondary").opacity(0.6))
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Methods

    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00 EEE, MMM d"
        return formatter.string(from: Date()).uppercased()
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
                .overlay(
                    Rectangle()
                        .fill(isSelected ? .white : .clear)
                        .frame(height: 2),
                    alignment: .bottom
                )
        }
    }
}

struct DayButton: View {
    let day: DailyForecast
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(day.qualityLevel.color == "#7BC043" ? .green : .yellow)
                        .frame(width: 8, height: 8)

                    Text("\(day.shortDayName) \(String(format: "%02d", day.dayNumber))")
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("Secondary").opacity(0.8) : .clear)
            )
        }
    }
}

struct MetricItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
        }
    }
}

struct CircularAQIGauge: View {
    let aqi: Int

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "#7BC043").opacity(0.3),
                            Color(hex: "#F9A825").opacity(0.3),
                            Color(hex: "#E53935").opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 12
                )
                .frame(width: 120, height: 120)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(aqi) / 150.0)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "#4CAF50"),
                            Color(hex: "#FFEB3B"),
                            Color(hex: "#FF9800"),
                            Color(hex: "#F44336")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            // AQI value
            VStack(spacing: 4) {
                Text("\(aqi)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)

                Text("AQI")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Indicator dot
            Circle()
                .fill(.yellow)
                .frame(width: 12, height: 12)
                .offset(y: -60)
                .rotationEffect(.degrees(Double(aqi) * 2.4))
        }
    }
}

struct AQIBarChart: View {
    let data: [HourlyAQIData]
    let selectedTime: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Time indicator line
                VStack {
                    Rectangle()
                        .fill(.white)
                        .frame(width: 2)
                }
                .frame(width: geometry.size.width / CGFloat(data.count))
                .offset(x: geometry.size.width / 2 - geometry.size.width / CGFloat(data.count) / 2)

                // Bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(data) { item in
                        VStack(spacing: 4) {
                            Spacer()

                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: item.qualityLevel.backgroundColor),
                                            Color(hex: item.qualityLevel.color)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: CGFloat(item.aqi) * 2)
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Time labels
                VStack {
                    Spacer()
                    HStack {
                        ForEach([0, 3, 6, 9, 11], id: \.self) { index in
                            if index < data.count {
                                Text(data[index].hour)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TipCategoryCard: View {
    let category: TipCategory

    var body: some View {
        VStack {
            Image(systemName: category.icon)
                .font(.system(size: 32))
                .foregroundColor(Color(hex: category.color))
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("Secondary").opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: category.color).opacity(0.3), lineWidth: 2)
                        )
                )
        }
    }
}

struct WeatherMetric: View {
    let icon: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .symbolRenderingMode(.multicolor)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(unit)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    DailyForecastView()
}
