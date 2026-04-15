//
//  LocationManager.swift
//  AcessNet
//
//  Gestor de ubicación con soporte para dirección, velocidad y heading
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {

    // MARK: - Properties

    private let locationManager = CLLocationManager()

    /// Ubicación actual del usuario
    @Published var userLocation: CLLocationCoordinate2D?

    /// Estado de autorización de ubicación
    @Published var authorizationStatus: CLAuthorizationStatus

    /// Dirección del usuario en grados (0-360°)
    @Published var heading: CLLocationDirection = 0

    /// Velocidad actual en m/s
    @Published var speed: CLLocationSpeed = 0

    /// Velocidad en km/h
    @Published var speedKmh: Double = 0

    /// Altitud actual en metros
    @Published var altitude: CLLocationDistance = 0

    /// Precisión de la ubicación
    @Published var accuracy: CLLocationAccuracy = 0

    /// Indica si el usuario se está moviendo
    @Published var isMoving: Bool = false

    /// Última ubicación completa
    @Published var lastLocation: CLLocation?

    // MARK: - Initialization

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Actualizar cada 50 metros (optimizado para performance)
        locationManager.headingFilter = 10 // Actualizar cada 10 grados

        checkLocationAuthorization()
    }

    // MARK: - Public Methods

    /// Verifica y solicita autorización de ubicación
    private func checkLocationAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading() // Iniciar actualizaciones de dirección
        case .restricted, .denied:
            print("⚠️ Permiso de ubicación denegado o restringido.")
        @unknown default:
            fatalError("Estado de autorización desconocido")
        }
    }

    /// Centra el mapa en la ubicación del usuario
    func centerOnUser() {
        if userLocation == nil {
            locationManager.requestLocation()
        }
    }

    /// Detiene las actualizaciones de ubicación (para ahorrar batería)
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    /// Reanuda las actualizaciones de ubicación
    func startUpdating() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        checkLocationAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Actualizar ubicación
        userLocation = location.coordinate
        lastLocation = location

        // Actualizar velocidad
        speed = max(0, location.speed) // -1 si no está disponible
        speedKmh = speed * 3.6 // Convertir m/s a km/h
        isMoving = speed > 0.5 // Considerar que se mueve si > 0.5 m/s (~1.8 km/h)

        // Actualizar altitud
        altitude = location.altitude

        // Actualizar precisión
        accuracy = location.horizontalAccuracy

        // Si la ubicación tiene course válido, usarlo como heading
        if location.course >= 0 {
            heading = location.course
        }

        print("📍 Ubicación actualizada: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("🏃 Velocidad: \(String(format: "%.1f", speedKmh)) km/h")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Usar el heading magnético si está disponible
        if newHeading.headingAccuracy >= 0 {
            heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            print("🧭 Dirección actualizada: \(String(format: "%.0f", heading))°")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Error al obtener la ubicación: \(error.localizedDescription)")
    }
}

// MARK: - Helper Extensions

extension LocationManager {

    /// Calcula la distancia entre dos coordenadas en metros
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }

        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let targetLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        return userLoc.distance(from: targetLoc)
    }

    /// Calcula el bearing (dirección) hacia una coordenada
    func bearing(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let userLocation = userLocation else { return nil }

        let lat1 = userLocation.latitude.degreesToRadians
        let lon1 = userLocation.longitude.degreesToRadians
        let lat2 = coordinate.latitude.degreesToRadians
        let lon2 = coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x).radiansToDegrees

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}
