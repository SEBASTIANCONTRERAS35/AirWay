//
//  AQIHomeView.swift
//  AcessNet
//
//  Created by BICHOTEE
//

import SwiftUI
import CoreLocation

struct AQIHomeView: View {
    @Binding var showBusinessPulse: Bool
    @EnvironmentObject var appSettings: AppSettings
    @State private var airQualityData: AirQualityData = .sample
    @State private var selectedForecastTab: ForecastTab = .hourly
    @State private var showSearchModal = false
    @State private var searchText = ""
    @State private var showARView = false
    @State private var isLoadingAQI: Bool = false

    private var theme: WeatherSimMode { appSettings.weatherSimMode }

    enum ForecastTab {
        case hourly
        case daily
    }

    init(showBusinessPulse: Binding<Bool>) {
        self._showBusinessPulse = showBusinessPulse
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo según Weather Simulation (Settings → Weather Simulation)
                theme.backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.45), value: theme)

                // Halo sutil con el accent del theme
                RadialGradient(
                    colors: [theme.accent.opacity(0.22), .clear],
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 360
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.45), value: theme)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        headerView

                        // AQI Info Button (combines AQI Card + PM Indicators)
                        aqiInfoButton

                        // AR Button
                        arButton

                        // Weather Info Card
                        weatherCard

                        // Today's Exposure
                        todaysExposureView

                        // Weather Forecast
                        weatherForecast
                    }
                    .padding(.top, 20)
                    .avoidTabBar(extraPadding: 20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $showARView) {
            ARParticlesView()
        }
        .sheet(isPresented: $showSearchModal) {
            LocationSearchModal(searchText: $searchText, onLocationSelected: handleLocationSelection)
        }
    }

    // MARK: - View Components

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.awAccent)
                            .font(.subheadline)

                        Text(airQualityData.location)
                            .font(.title3.bold())
                            .foregroundColor(.awInk)

                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundColor(.awInkSoft)
                            .font(.subheadline)
                    }

                    Text(airQualityData.city)
                        .font(.subheadline)
                        .foregroundColor(.awInkSoft)

                    Text("Nearest Monitor : \(String(format: "%.2f", airQualityData.distance)) Km")
                        .font(.caption)
                        .foregroundColor(.awInkMuted)
                }

                Spacer()

                // Search button
                Button(action: {
                    showSearchModal = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.awInk)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.awSurface)
                                .overlay(
                                    Circle()
                                        .stroke(Color.awBorderStrong, lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(.horizontal)
    }

    private var aqiCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 10, height: 10)
                            .shadow(color: .red, radius: 4)

                        Text("Live AQI")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }

                    Text("\(airQualityData.aqi)")
                        .font(.system(size: 90, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Text("Air Quality is")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.95))

                    Text(airQualityData.qualityLevel.rawValue)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: airQualityData.qualityLevel.color).opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(.white.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private var dailyForecastButton: some View {
        NavigationLink(destination: DailyForecastView()) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("5-Day Forecast")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("View detailed daily air quality predictions")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("Secondary").opacity(0.7),
                                Color("Primary").opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
        }
        .padding(.horizontal)
    }

    private var aqiInfoButton: some View {
        NavigationLink(destination: DailyForecastView()) {
            VStack(spacing: 16) {
                // AQI Card content
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.awAccent)
                                .frame(width: 10, height: 10)
                                .shadow(color: Color.awAccent.opacity(0.8), radius: 4)

                            Text("Live AQI")
                                .font(.subheadline.bold())
                                .foregroundColor(.awInkSoft)
                                .tracking(0.6)
                        }

                        Text("\(airQualityData.aqi)")
                            .font(.system(size: 90, weight: .heavy))
                            .foregroundColor(.awInk)
                            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        Text("Air Quality is")
                            .font(.subheadline)
                            .foregroundColor(.awInkSoft)

                        Text(airQualityData.qualityLevel.rawValue)
                            .font(.title2.bold())
                            .foregroundColor(.awInk)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(hex: airQualityData.qualityLevel.color).opacity(0.85))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.awBorderStrong, lineWidth: 1.5)
                                    )
                                    .shadow(color: Color(hex: airQualityData.qualityLevel.color).opacity(0.35), radius: 10, x: 0, y: 4)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // PM Indicators with daily comparison
                HStack(spacing: 20) {
                    // PM2.5
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PM2.5")
                            .font(.caption)
                            .foregroundColor(.awInkMuted)

                        Text("\(Int(airQualityData.pm25)) μg/m³")
                            .font(.subheadline.bold())
                            .foregroundColor(.awInk)
                    }

                    // PM10
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PM10")
                            .font(.caption)
                            .foregroundColor(.awInkMuted)

                        Text("\(Int(airQualityData.pm10)) μg/m³")
                            .font(.subheadline.bold())
                            .foregroundColor(.awInk)
                    }

                    Spacer()

                    // Daily comparison dots
                    HStack(spacing: 8) {
                        DayDot(label: "Tue", aqi: 52)
                        DayDot(label: "Wed", aqi: 58)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.awSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.awBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
            )
        }
        .padding(.horizontal)
    }

    private var arButton: some View {
        Button(action: {
            showARView = true
        }) {
            HStack(spacing: 16) {
                // AR Icon (accent gradient para reforzar la marca)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.awAccent, Color.awPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.awAccent.opacity(0.45), radius: 10, x: 0, y: 4)

                    Image(systemName: "camera.metering.center.weighted")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.awInk)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text("AR Air Quality")
                        .font(.headline)
                        .foregroundColor(.awInk)

                    Text("Visualize invisible PM2.5 particles")
                        .font(.subheadline)
                        .foregroundColor(.awInkSoft)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.awInkMuted)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.awSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.awAccent.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: Color.awAccent.opacity(0.18), radius: 14, x: 0, y: 6)
            )
        }
        .padding(.horizontal)
    }

    private var pmIndicators: some View {
        HStack(spacing: 24) {
            // PM2.5 - Simplified
            HStack(spacing: 8) {
                Text("PM2.5:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Text("\(Int(airQualityData.pm25)) μg/m³")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }

            // PM10 - Simplified
            HStack(spacing: 8) {
                Text("PM10:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Text("\(Int(airQualityData.pm10)) μg/m³")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }

    private var weatherCard: some View {
        VStack(spacing: 16) {
            // Weather scale bar
            AQIScaleBar(currentAQI: airQualityData.aqi)
                .padding(.horizontal)

            // Weather info card
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    WeatherInfoItem(
                        icon: "cloud.fill",
                        value: "\(Int(airQualityData.temperature))°",
                        unit: "C",
                        label: airQualityData.weatherCondition.rawValue
                    )

                    Divider().frame(height: 60).background(Color.awBorder)

                    WeatherInfoItem(
                        icon: "drop.fill",
                        value: "\(airQualityData.humidity)",
                        unit: "%",
                        label: "Humidity"
                    )

                    Divider().frame(height: 60).background(Color.awBorder)

                    WeatherInfoItem(
                        icon: "wind",
                        value: "\(Int(airQualityData.windSpeed))",
                        unit: "km/hr",
                        label: "Wind"
                    )

                    Divider().frame(height: 60).background(Color.awBorder)

                    WeatherInfoItem(
                        icon: "sun.max.fill",
                        value: "\(airQualityData.uvIndex)",
                        unit: "",
                        label: "UV Index"
                    )
                }
                .padding(.vertical, 8)

                Text("Last Update:  \(airQualityData.timeAgo)")
                    .font(.caption)
                    .foregroundColor(.awInkMuted)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.awSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.awBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 6)
            )
            .padding(.horizontal)
        }
    }

    private var todaysExposureView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's exposure")
                .font(.title2.bold())
                .foregroundColor(.awInk)
                .padding(.horizontal)

            // Exposure Chart
            ExposureCircularChart()
                .frame(height: 280)
                .padding(.horizontal)
        }
    }

    private var mascotView: some View {
        HStack {
            Spacer()
            MascotCharacter()
                .frame(height: 180)
                .padding(.trailing, 40)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }

    private var weatherForecast: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weather Forecast")
                .font(.title3.bold())
                .foregroundColor(.awInk)
                .padding(.horizontal)

            // Tabs
            HStack(spacing: 8) {
                ForecastTabButton(
                    title: "Hourly",
                    isSelected: selectedForecastTab == .hourly
                ) {
                    withAnimation(.none) {
                        selectedForecastTab = .hourly
                    }
                }

                ForecastTabButton(
                    title: "Daily",
                    isSelected: selectedForecastTab == .daily
                ) {
                    withAnimation(.none) {
                        selectedForecastTab = .daily
                    }
                }
            }
            .padding(.horizontal)

            // Forecast content with sample data
            if selectedForecastTab == .hourly {
                hourlyForecastView
                    .transition(.identity)
            } else {
                dailyForecastView
                    .transition(.identity)
            }
        }
    }

    private var hourlyForecastView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                HourlyForecastItem(hour: "Now", temp: 16, icon: "cloud.rain.fill")
                HourlyForecastItem(hour: "19:00", temp: 15, icon: "cloud.rain.fill")
                HourlyForecastItem(hour: "20:00", temp: 15, icon: "cloud.rain.fill")
                HourlyForecastItem(hour: "21:00", temp: 14, icon: "cloud.rain.fill")
                HourlyForecastItem(hour: "22:00", temp: 14, icon: "cloud.rain.fill")
                HourlyForecastItem(hour: "23:00", temp: 14, icon: "cloud.rain.fill")
                HourlyForecastItem(hour: "00:00", temp: 13, icon: "cloud.moon.rain.fill")
            }
            .padding(.horizontal)
        }
    }

    private var dailyForecastView: some View {
        VStack(spacing: 16) {
            // Daily forecast cards
            ForEach(generateDailyForecasts()) { forecast in
                NavigationLink(destination: DailyForecastView()) {
                    DailyForecastCard(forecast: forecast)
                }
            }
        }
        .padding(.horizontal)
    }

    private func generateDailyForecasts() -> [DailyForecastData] {
        let calendar = Calendar.current
        let today = Date()

        return [
            DailyForecastData(
                id: 0,
                date: calendar.date(byAdding: .day, value: 0, to: today)!,
                dayName: "Today",
                aqi: 58,
                temp: 16,
                weatherIcon: "cloud.rain.fill",
                weatherDescription: "Rainy",
                qualityLevel: "Moderate"
            ),
            DailyForecastData(
                id: 1,
                date: calendar.date(byAdding: .day, value: 1, to: today)!,
                dayName: "Tomorrow",
                aqi: 45,
                temp: 17,
                weatherIcon: "cloud.sun.fill",
                weatherDescription: "Partly Cloudy",
                qualityLevel: "Good"
            ),
            DailyForecastData(
                id: 2,
                date: calendar.date(byAdding: .day, value: 2, to: today)!,
                dayName: "Saturday",
                aqi: 62,
                temp: 18,
                weatherIcon: "cloud.fill",
                weatherDescription: "Cloudy",
                qualityLevel: "Moderate"
            ),
            DailyForecastData(
                id: 3,
                date: calendar.date(byAdding: .day, value: 3, to: today)!,
                dayName: "Sunday",
                aqi: 38,
                temp: 19,
                weatherIcon: "sun.max.fill",
                weatherDescription: "Sunny",
                qualityLevel: "Good"
            ),
            DailyForecastData(
                id: 4,
                date: calendar.date(byAdding: .day, value: 4, to: today)!,
                dayName: "Monday",
                aqi: 71,
                temp: 15,
                weatherIcon: "cloud.drizzle.fill",
                weatherDescription: "Drizzle",
                qualityLevel: "Moderate"
            )
        ]
    }
}

struct DailyForecastCard: View {
    let forecast: DailyForecastData

    var body: some View {
        HStack(spacing: 16) {
            // Left section - Day and Date
            VStack(alignment: .leading, spacing: 4) {
                Text(forecast.dayName)
                    .font(.headline)
                    .foregroundColor(.awInk)

                Text(formatDate(forecast.date))
                    .font(.caption)
                    .foregroundColor(.awInkMuted)
            }
            .frame(width: 85, alignment: .leading)

            // AQI Badge
            VStack(spacing: 4) {
                Text("\(forecast.aqi)")
                    .font(.title2.bold())
                    .foregroundColor(.awInk)

                Text("AQI")
                    .font(.caption2)
                    .foregroundColor(.awInkSoft)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(forecast.aqiColor.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(forecast.aqiColor, lineWidth: 1.5)
                    )
            )

            Spacer()

            // Weather section
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(forecast.weatherDescription)
                        .font(.subheadline)
                        .foregroundColor(.awInk)

                    Text("\(forecast.temp)°C")
                        .font(.caption)
                        .foregroundColor(.awInkSoft)
                }

                Image(systemName: forecast.weatherIcon)
                    .font(.title2)
                    .foregroundColor(.awInk)
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 35)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.awInkMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.awSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.awBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 5)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

extension AQIHomeView {
    // MARK: - Location Selection Handler

    fileprivate func handleLocationSelection(_ locationString: String) {
        // Parse location string (e.g., "Mexico City, Mexico")
        let components = locationString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let locationName = components.first ?? locationString
        let cityName = locationString

        // Fetch AQI data for selected location
        fetchAQIData(locationName: locationName, cityName: cityName)
    }

    // MARK: - Fetch AQI Data
    fileprivate func fetchAQIData(locationName: String, cityName: String) {
        // Show loading state
        isLoadingAQI = true

        // Simulate API call - En producción, aquí se haría la llamada real a NASA TEMPO o OpenAQ
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create new air quality data with selected location
            let newAQI = Int.random(in: 50...150)
            let newPM25 = Double.random(in: 15...35)
            let newPM10 = Double.random(in: 40...80)

            self.airQualityData = AirQualityData(
                aqi: newAQI,
                pm25: newPM25,
                pm10: newPM10,
                location: locationName,
                city: cityName,
                distance: Double.random(in: 0.5...5.0),
                temperature: Double.random(in: 15...25),
                humidity: Int.random(in: 50...80),
                windSpeed: Double.random(in: 2...8),
                uvIndex: Int.random(in: 0...5),
                weatherCondition: .overcast,
                lastUpdate: Date()
            )

            // Hide loading state
            self.isLoadingAQI = false
        }
    }
}

// MARK: - Supporting Views

struct PMIndicator: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.9))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(value))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct AQIScaleBar: View {
    let currentAQI: Int

    var body: some View {
        VStack(spacing: 8) {
            // Scale labels
            HStack {
                Text("Good").font(.caption2).foregroundColor(.awInkSoft)
                Spacer()
                Text("Moderate").font(.caption2).foregroundColor(.awInkSoft)
                Spacer()
                Text("Poor").font(.caption2).foregroundColor(.awInkSoft)
                Spacer()
                Text("Unhealthy").font(.caption2).foregroundColor(.awInkSoft)
                Spacer()
                Text("Severe").font(.caption2).foregroundColor(.awInkSoft)
                Spacer()
                Text("Hazardous").font(.caption2).foregroundColor(.awInkSoft)
            }

            // Scale bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient
                    LinearGradient(
                        colors: [
                            Color(hex: "#7BC043"),
                            Color(hex: "#F9A825"),
                            Color(hex: "#FF6F00"),
                            Color(hex: "#E53935"),
                            Color(hex: "#8E24AA"),
                            Color(hex: "#6A1B4D")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Current position indicator
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(radius: 4)
                        .offset(x: CGFloat(currentAQI) / 301.0 * geometry.size.width - 10)
                }
            }
            .frame(height: 12)

            // Scale numbers
            HStack {
                ForEach([0, 50, 100, 150, 200, 301], id: \.self) { number in
                    Text("\(number)")
                        .font(.caption2)
                        .foregroundColor(.awInkMuted)
                    if number != 301 {
                        Spacer()
                    }
                }

                Text("301+")
                    .font(.caption2)
                    .foregroundColor(.awInkMuted)
            }
        }
    }
}

struct WeatherInfoItem: View {
    let icon: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.awAccent)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.awInk)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.awInkMuted)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.awInkSoft)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ForecastTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .awPrimary : .awInkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isSelected ? Color.awInk : Color.awSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(isSelected ? Color.clear : Color.awBorder, lineWidth: 1)
                        )
                )
        }
    }
}

struct HourlyForecastItem: View {
    let hour: String
    let temp: Int
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Text(hour)
                .font(.caption)
                .foregroundColor(.awInkSoft)

            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.awInk)
                .symbolRenderingMode(.multicolor)

            Text("\(temp)°")
                .font(.title3.bold())
                .foregroundColor(.awInk)
        }
        .frame(width: 60)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.awSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.awBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Exposure Circular Chart

struct ExposureCircularChart: View {
    @State private var selectedCategory = "All"
    let categories = ["All", "Home", "Work", "Outdoor"]

    // Sample data: hours spent in each environment (today's data)
    let homeHours: CGFloat = 6
    let workHours: CGFloat = 4
    let outdoorHours: CGFloat = 3

    var totalHours: CGFloat {
        homeHours + workHours + outdoorHours
    }

    var showHome: Bool {
        selectedCategory == "All" || selectedCategory == "Home"
    }

    var showWork: Bool {
        selectedCategory == "All" || selectedCategory == "Work"
    }

    var showOutdoor: Bool {
        selectedCategory == "All" || selectedCategory == "Outdoor"
    }

    var body: some View {
        VStack(spacing: 12) {
            // Category tabs
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    ExposureCategoryTabHome(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }

            // Circular clock-style chart
            ZStack {
                // Hour markers and labels
                ForEach(0..<24) { hour in
                    HourMarker(hour: hour, totalHours: totalHours)
                }

                // Colored segments - conditional display with animations
                ZStack {
                    // Home segment (Yellow)
                    if showHome {
                        SegmentArc(
                            startHour: 0,
                            endHour: homeHours,
                            color: Color(hex: "#FFD54F"),
                            label: "HOME",
                            hours: homeHours
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Work segment (Green)
                    if showWork {
                        SegmentArc(
                            startHour: homeHours,
                            endHour: homeHours + workHours,
                            color: Color(hex: "#81C784"),
                            label: "WORK",
                            hours: workHours
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Outdoor segment (Orange)
                    if showOutdoor {
                        SegmentArc(
                            startHour: homeHours + workHours,
                            endHour: homeHours + workHours + outdoorHours,
                            color: Color(hex: "#FFA726"),
                            label: "OUTDOOR",
                            hours: outdoorHours
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // Center content
                VStack(spacing: 8) {
                    if selectedCategory == "All" {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))

                        Text("\(Int(totalHours))h")
                            .font(.title3.bold())
                            .foregroundColor(.white.opacity(0.6))

                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        let hours = selectedCategory == "Home" ? homeHours :
                                   selectedCategory == "Work" ? workHours : outdoorHours

                        Text("\(Int(hours))h")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundColor(.white)

                        Text(selectedCategory.uppercased())
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(height: 240)
        }
    }
}

struct ExposureCategoryTabHome: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    private var categoryColor: Color {
        switch title {
        case "Home": return Color(hex: "#FFD54F")
        case "Work": return Color(hex: "#81C784")
        case "Outdoor": return Color(hex: "#FFA726")
        default: return .white
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? categoryColor.opacity(0.3) : Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? categoryColor : .clear, lineWidth: 2)
                        )
                )
        }
    }
}

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.2))
                )
        }
    }
}

struct HourMarker: View {
    let hour: Int
    let totalHours: CGFloat

    var body: some View {
        VStack {
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: hour % 3 == 0 ? 2 : 1, height: hour % 3 == 0 ? 12 : 6)

            Spacer()

            if hour % 3 == 0 {
                Text("\(hour)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .offset(y: -10)
            }
        }
        .frame(width: 100, height: 100)
        .rotationEffect(.degrees(Double(hour) * 15))
    }
}

struct SegmentArc: View {
    let startHour: CGFloat
    let endHour: CGFloat
    let color: Color
    let label: String
    let hours: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .trim(from: startHour / 24, to: endHour / 24)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 35
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 0)
        }
    }
}

// MARK: - Location Search Modal

struct LocationSearchModal: View {
    @Binding var searchText: String
    @Environment(\.dismiss) var dismiss
    @State private var searchResults: [String] = []
    var onLocationSelected: (String) -> Void

    let quickLocations = [
        ("Mexico City, Mexico", "mappin.circle.fill"),
        ("New York, USA", "building.2.fill"),
        ("Tokyo, Japan", "building.fill"),
        ("London, UK", "building.columns.fill"),
        ("Paris, France", "sparkles")
    ]

    var body: some View {
        ZStack {
            // Background gradient - Using app colors
            LinearGradient(
                colors: [
                    Color("Secondary"),
                    Color("Primary"),
                    Color("Secondary")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .padding(.top, 10)

                // Enhanced Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))

                    TextField("Search location...", text: $searchText)
                        .font(.body)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

                // Results or Quick Navigation
                ScrollView {
                    if searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            // Quick Navigation Header
                            Text("Quick Navigation")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)

                            // Quick location buttons
                            VStack(spacing: 12) {
                                ForEach(quickLocations, id: \.0) { location in
                                    Button(action: {
                                        onLocationSelected(location.0)
                                        dismiss()
                                    }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: location.1)
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .frame(width: 40)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(location.0)
                                                    .font(.body.bold())
                                                    .foregroundColor(.white)

                                                Text("View air quality")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.white.opacity(0.15))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredLocations, id: \.self) { location in
                                Button(action: {
                                    onLocationSelected(location)
                                    dismiss()
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .frame(width: 40)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(location)
                                                .font(.body.bold())
                                                .foregroundColor(.white)

                                            Text("Tap to view air quality")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.white.opacity(0.15))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
        }
    }

    var filteredLocations: [String] {
        let sampleLocations = [
            "Mexico City, Mexico",
            "New York, USA",
            "Los Angeles, USA",
            "London, UK",
            "Tokyo, Japan",
            "Paris, France",
            "Berlin, Germany",
            "Madrid, Spain"
        ]

        if searchText.isEmpty {
            return sampleLocations
        } else {
            return sampleLocations.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
}


// MARK: - Day Comparison Dot

struct DayDot: View {
    let label: String
    let aqi: Int

    var dotColor: Color {
        switch aqi {
        case 0..<51: return Color(hex: "#7BC043")
        case 51..<101: return Color(hex: "#FDD835")
        case 101..<151: return Color(hex: "#FF9800")
        default: return Color(hex: "#E53935")
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                )

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Daily Forecast Data Model

struct DailyForecastData: Identifiable {
    let id: Int
    let date: Date
    let dayName: String
    let aqi: Int
    let temp: Int
    let weatherIcon: String
    let weatherDescription: String
    let qualityLevel: String

    var aqiColor: Color {
        switch aqi {
        case 0..<51: return Color(hex: "#7BC043")
        case 51..<101: return Color(hex: "#FDD835")
        case 101..<151: return Color(hex: "#FF9800")
        default: return Color(hex: "#E53935")
        }
    }
}

#Preview {
    AQIHomeView(showBusinessPulse: .constant(false))
}

