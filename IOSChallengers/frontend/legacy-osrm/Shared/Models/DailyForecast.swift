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
        ),
        DailyForecast(
            date: Date().addingTimeInterval(86400 * 3),
            dayName: "SUN",
            dayNumber: 5,
            aqi: 37,
            no2: 35,
            pm25: 30,
            pm10: 12,
            o3: 18,
            temperature: 11,
            windSpeed: 1,
            uvIndex: 0,
            humidity: 83
        ),
        DailyForecast(
            date: Date().addingTimeInterval(86400 * 4),
            dayName: "MON",
            dayNumber: 6,
            aqi: 42,
            no2: 40,
            pm25: 35,
            pm10: 14,
            o3: 20,
            temperature: 12,
            windSpeed: 1,
            uvIndex: 0,
            humidity: 80
        )
    ]

    static let selected = sampleWeek[2] // SAT 04
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
                "Stay hydrated during exercise"
            ]
        ),
        TipCategory(
            icon: "bicycle",
            title: "Cycling",
            color: "#2196F3",
            tips: [
                "Good conditions for cycling",
                "Wear a mask if you have respiratory issues",
                "Avoid peak traffic hours"
            ]
        ),
        TipCategory(
            icon: "heart.fill",
            title: "Health",
            color: "#FF5722",
            tips: [
                "People with respiratory conditions should be cautious",
                "Keep windows closed if AQI increases",
                "Check AQI before outdoor activities"
            ]
        ),
        TipCategory(
            icon: "house.fill",
            title: "Indoor",
            color: "#9C27B0",
            tips: [
                "Use air purifiers if available",
                "Maintain good ventilation",
                "Clean surfaces regularly"
            ]
        )
    ]
}
