//
//  LocationSearchManager.swift
//  AcessNet
//
//  Gestor de búsqueda de ubicaciones con autocompletado
//

import Foundation
import MapKit
import Combine
import CoreLocation

class LocationSearchManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Texto de búsqueda actual
    @Published var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                searchResults = []
            } else {
                performSearch()
            }
        }
    }

    /// Resultados de búsqueda (sugerencias de autocompletado)
    @Published var searchResults: [SearchResult] = []

    /// Indica si está buscando activamente
    @Published var isSearching: Bool = false

    /// Mensaje de error si la búsqueda falla
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let searchCompleter = MKLocalSearchCompleter()
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    /// Región de búsqueda (se actualiza con ubicación del usuario)
    private var searchRegion: MKCoordinateRegion?

    // MARK: - Initialization

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    // MARK: - Public Methods

    /// Actualiza la región de búsqueda basada en ubicación del usuario
    func updateSearchRegion(center: CLLocationCoordinate2D, radiusInMeters: Double = 50000) {
        let span = MKCoordinateSpan(
            latitudeDelta: radiusInMeters / 111000, // aproximadamente 111km por grado
            longitudeDelta: radiusInMeters / 111000
        )
        searchRegion = MKCoordinateRegion(center: center, span: span)
        searchCompleter.region = searchRegion!
    }

    /// Limpia la búsqueda y resultados
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        errorMessage = nil
        isSearching = false
        searchTask?.cancel()
    }

    /// Selecciona un resultado y obtiene sus coordenadas completas
    func selectResult(_ result: SearchResult, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        // Si ya tiene coordenadas, retornarlas
        if let coordinate = result.coordinate {
            completion(coordinate)
            return
        }

        // Si no, hacer búsqueda completa para obtener coordenadas
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = result.title + " " + result.subtitle

        if let region = searchRegion {
            searchRequest.region = region
        }

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let error = error {
                print("❌ Error al obtener coordenadas: \(error.localizedDescription)")
                self.errorMessage = "Could not find location"
                completion(nil)
                return
            }

            guard let mapItem = response?.mapItems.first else {
                completion(nil)
                return
            }

            completion(mapItem.placemark.coordinate)
        }
    }

    // MARK: - Private Methods

    private func performSearch() {
        // Cancelar búsqueda previa
        searchTask?.cancel()

        // Debouncing: esperar 0.3 segundos antes de buscar
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 segundos

                // Verificar si no fue cancelado
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.isSearching = true
                    self.searchCompleter.queryFragment = self.searchQuery
                }
            } catch {
                // Task fue cancelado, ignorar
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchManager: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            // Convertir completions a SearchResults
            self.searchResults = completer.results.prefix(8).map { completion in
                SearchResult(from: completion)
            }

            self.isSearching = false
            self.errorMessage = nil

            print("🔍 Encontrados \(self.searchResults.count) resultados para '\(self.searchQuery)'")
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            self.errorMessage = "Search failed: \(error.localizedDescription)"
            self.searchResults = []

            print("❌ Error en búsqueda: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Extensions

extension LocationSearchManager {

    /// Realiza una búsqueda directa por coordenadas (geocodificación inversa)
    func reverseGeocode(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("❌ Error en geocodificación inversa: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }

            // Formatear dirección
            var addressComponents: [String] = []

            if let name = placemark.name {
                addressComponents.append(name)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            if let administrativeArea = placemark.administrativeArea {
                addressComponents.append(administrativeArea)
            }

            let address = addressComponents.joined(separator: ", ")
            completion(address)
        }
    }

    /// Busca lugares cercanos a una coordenada con una categoría específica
    func searchNearby(coordinate: CLLocationCoordinate2D, query: String, completion: @escaping ([SearchResult]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        // Región de 5km alrededor de la coordenada
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        request.region = MKCoordinateRegion(center: coordinate, span: span)

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("❌ Error en búsqueda cercana: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let mapItems = response?.mapItems else {
                completion([])
                return
            }

            let results = mapItems.prefix(10).map { SearchResult(from: $0) }
            completion(results)
        }
    }
}
