//
//  DailyForecast.swift
//  AcessNet
//
//  Created by BICHOTEE
//

import Foundation

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let dayNumber: Int
    let aqi: Int
    let no2: Int
    let pm25: Int
    let pm10: Int
    let o3: Int
    let temperature: Int
    let windSpeed: Int
    let uvIndex: Int
    let humidity: Int

    var qualityLevel: AQILevel {
        AQILevel.from(aqi: aqi)
    }

    var shortDayName: String {
        String(dayName.prefix(3)).uppercased()
    }
}

struct HourlyAQIData: Identifiable {
    let id = UUID()
    let hour: String
    let aqi: Int
    let timestamp: Date

    var qualityLevel: AQILevel {
        AQILevel.from(aqi: aqi)
    }
}

struct TipCategory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: String
    let tips: [String]
}

// MARK: - Sample Data

extension DailyForecast {
    static let sampleWeek: [DailyForecast] = [
        // Yesterday
        DailyForecast(
            date: Date().addingTimeInterval(-86400),
            dayName: "WED",
            dayNumber: 1,
            aqi: 48,
            no2: 45,
            pm25: 40,
            pm10: 16,
            o3: 24,
            temperature: 16,
            windSpeed: 1,
            uvIndex: 0,
            humidity: 75
        ),
        // Today
        DailyForecast(
            date: Date(),
            dayName: "THU",
            dayNumber: 2,
            aqi: 45,
            no2: 42,
            pm25: 38,
            pm10: 15,
            o3: 22,
            temperature: 15,
            windSpeed: 1,
            uvIndex: 0,
            humidity: 78
        ),
        DailyForecast(
            date: Date().addingTimeInterval(86400),
            dayName: "FRI",
            dayNumber: 3,
            aqi: 53,
            no2: 50,
            pm25: 53,
            pm10: 21,
            o3: 27,
            temperature: 14,
            windSpeed: 0,
            uvIndex: 0,
            humidity: 76
        ),
        // Day after tomorrow (max 2 days from today)
        DailyForecast(
            date: Date().addingTimeInterval(86400 * 2),
            dayName: "SAT",
            dayNumber: 4,
            aqi: 53,
            no2: 50,
            pm25: 53,
            pm10: 21,
            o3: 27,
            temperature: 16,
            windSpeed: 1,
            uvIndex: 0,
            humidity: 72
        )
    ]

    static let selected = sampleWeek[1] // Today (THU 02)
}

extension HourlyAQIData {
    static func generateSampleDay() -> [HourlyAQIData] {
        let hours = ["0:00", "2:00", "4:00", "6:00", "8:00", "10:00", "12:00", "14:00", "16:00", "18:00", "20:00", "22:00"]
        let aqiValues = [35, 40, 45, 50, 55, 60, 58, 55, 52, 48, 45, 40]

        return zip(hours, aqiValues).map { hour, aqi in
            HourlyAQIData(
                hour: hour,
                aqi: aqi,
                timestamp: Date()
            )
        }
    }
}

extension TipCategory {
    static let sampleCategories: [TipCategory] = [
        TipCategory(
            icon: "figure.run",
            title: "Running",
            color: "#4CAF50",
            tips: [
                "Moderate air quality - suitable for outdoor activities",
                "Consider lighter intensity workouts if sensitive",
                "Stay hydrated during exercise",
                "Did you know? Morning air is typically 40% cleaner than afternoon",
                "Best running hours: 6-8 AM when pollution is lowest",
                "Running in parks reduces PM2.5 exposure by 25%",
                "Breathing through your nose filters 80% of particles",
                "Fun fact: Trees along running paths absorb 20kg of pollutants yearly"
            ]
        ),
        TipCategory(
            icon: "bicycle",
            title: "Cycling",
            color: "#2196F3",
            tips: [
                "Good conditions for cycling",
                "Wear a mask if you have respiratory issues",
                "Avoid peak traffic hours",
                "Did you know? Cyclists inhale 2x more air than pedestrians",
                "Bike lanes away from traffic reduce exposure by 30%",
                "Fun fact: Electric bikes help reduce breathing rate and pollution intake",
                "Cycling after rain reduces particle exposure by 60%",
                "Using bike paths instead of roads cuts pollution exposure in half"
            ]
        ),
        TipCategory(
            icon: "heart.fill",
            title: "Health",
            color: "#FF5722",
            tips: [
                "People with respiratory conditions should be cautious",
                "Keep windows closed if AQI increases",
                "Check AQI before outdoor activities",
                "Did you know? Indoor air can be 5x more polluted than outdoor",
                "Plants like spider plants remove 87% of toxins in 24 hours",
                "Fun fact: Air purifiers reduce asthma symptoms by 40%",
                "Opening windows during low AQI hours improves sleep quality",
                "Vitamin C intake helps reduce effects of air pollution by 30%"
            ]
        ),
        TipCategory(
            icon: "house.fill",
            title: "Indoor",
            color: "#9C27B0",
            tips: [
                "Use air purifiers if available",
                "Maintain good ventilation",
                "Clean surfaces regularly",
                "Did you know? Cooking can spike indoor PM2.5 by 300%",
                "Fun fact: Bamboo charcoal bags absorb odors and pollutants naturally",
                "Opening windows for 15 minutes daily reduces indoor CO2 by 50%",
                "HEPA filters capture 99.97% of particles as small as 0.3 microns",
                "Houseplants can improve indoor air quality by up to 25%"
            ]
        )
    ]
}
