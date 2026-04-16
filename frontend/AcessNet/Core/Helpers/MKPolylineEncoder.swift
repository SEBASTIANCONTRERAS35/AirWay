//
//  MKPolylineEncoder.swift
//  AcessNet
//
//  Codifica MKPolyline al formato Google Encoded Polyline (precision 5)
//  que usa OSRM/Mapbox/Django backend.
//
//  Referencia: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
//

import Foundation
import MapKit

enum MKPolylineEncoder {
    /// Codifica un MKPolyline al formato Google Encoded Polyline Algorithm (precision 5).
    static func encode(_ polyline: MKPolyline) -> String {
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return "" }

        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

        return encode(coords: coords)
    }

    /// Codifica un array de CLLocationCoordinate2D.
    static func encode(coords: [CLLocationCoordinate2D], precision: Double = 1e5) -> String {
        var result = ""
        var prevLat = 0
        var prevLon = 0

        for coord in coords {
            let lat = Int((coord.latitude * precision).rounded())
            let lon = Int((coord.longitude * precision).rounded())
            result.append(encodeValue(lat - prevLat))
            result.append(encodeValue(lon - prevLon))
            prevLat = lat
            prevLon = lon
        }

        return result
    }

    private static func encodeValue(_ value: Int) -> String {
        var v = value < 0 ? ~(value << 1) : (value << 1)
        var result = ""
        while v >= 0x20 {
            let chunk = (0x20 | (v & 0x1f)) + 63
            result.append(Character(UnicodeScalar(chunk)!))
            v >>= 5
        }
        result.append(Character(UnicodeScalar(v + 63)!))
        return result
    }
}
