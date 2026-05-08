import Foundation
import CoreLocation
import FirebaseFirestore

struct Letter: Identifiable, Codable {
    @DocumentID var id: String?
    let text: String
    let latitude: Double
    let longitude: Double
    let createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
