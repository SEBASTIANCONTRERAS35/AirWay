//
//  Country.swift
//  AcessNet
//
//  Created by Emilio Cruz Vargas on 21/09/25.
//

import Foundation

struct Country: Identifiable, Hashable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    let dialCode: String
    let flag: String
}

class CountryData {
    static let countries: [Country] = [
        Country(code: "US", name: "United States", dialCode: "+1", flag: "🇺🇸"),
        Country(code: "MX", name: "Mexico", dialCode: "+52", flag: "🇲🇽"),
        Country(code: "ES", name: "Spain", dialCode: "+34", flag: "🇪🇸"),
        Country(code: "CO", name: "Colombia", dialCode: "+57", flag: "🇨🇴"),
        Country(code: "AR", name: "Argentina", dialCode: "+54", flag: "🇦🇷"),
        Country(code: "PE", name: "Peru", dialCode: "+51", flag: "🇵🇪"),
        Country(code: "BR", name: "Brazil", dialCode: "+55", flag: "🇧🇷"),
        Country(code: "FR", name: "France", dialCode: "+33", flag: "🇫🇷"),
        Country(code: "DE", name: "Germany", dialCode: "+49", flag: "🇩🇪"),
        Country(code: "UK", name: "United Kingdom", dialCode: "+44", flag: "🇬🇧"),
        // Agrega más países aquí...
    ]
}
