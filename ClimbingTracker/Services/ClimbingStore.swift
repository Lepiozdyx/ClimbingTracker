import Foundation
import Combine
import UIKit

@MainActor
final class ClimbingStore: ObservableObject {


    @Published private(set) var places: [Place] = []
    @Published private(set) var routes: [Route] = []
    @Published private(set) var climbings: [Climbing] = []

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private let payloadKey = "climbing_tracker_payload_v3_climbing"

    private let photoStorage: PhotoFileStorage
    private let userDefaults: UserDefaults

       init(userDefaults: UserDefaults = .standard) {
           self.userDefaults = userDefaults
           self.photoStorage = PhotoFileStorage.shared

           let enc = JSONEncoder()
           let dec = JSONDecoder()
           enc.dateEncodingStrategy = .iso8601
           dec.dateDecodingStrategy = .iso8601
           self.encoder = enc
           self.decoder = dec

           load()
       }


    func routes(for placeId: UUID) -> [Route] {
        routes
            .filter { $0.placeId == placeId }
            .sorted { $0.grade.rank < $1.grade.rank }
    }

    func climbingsSortedNewestFirst() -> [Climbing] {
        climbings.sorted { $0.date > $1.date }
    }

    func hasClimbings(on day: Date, calendar: Calendar = .current) -> Bool {
        let target = day.startOfDay(in: calendar)
        return climbings.contains { $0.date.startOfDay(in: calendar) == target }
    }

    func climbings(on day: Date, calendar: Calendar = .current) -> [Climbing] {
        let target = day.startOfDay(in: calendar)
        return climbings
            .filter { $0.date.startOfDay(in: calendar) == target }
            .sorted { $0.date > $1.date }
    }

    func photoData(for photo: ClimbingPhoto) -> Data? {
        do {
            return try photoStorage.loadData(filename: photo.filename)
        } catch {
            print("❌ Photo read error:", error)
            return nil
        }
    }

    func photoURL(for photo: ClimbingPhoto) -> URL? {
        do {
            return try photoStorage.fileURL(filename: photo.filename)
        } catch {
            print("❌ Photo URL error:", error)
            return nil
        }
    }


    func addPlace(name: String, kind: PlaceKind, details: String) {
        let place = Place(name: name, kind: kind, details: details)
        places.append(place)
        places.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func updatePlace(_ place: Place) {
        guard let idx = places.firstIndex(where: { $0.id == place.id }) else { return }
        places[idx] = place
        places.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func deletePlace(id: UUID) {
        let routeIdsToDelete = Set(routes.filter { $0.placeId == id }.map { $0.id })

        let filenamesToDelete = climbings
            .filter { $0.placeId == id || routeIdsToDelete.contains($0.routeId) }
            .flatMap { $0.photos.map(\.filename) }

        photoStorage.delete(filenames: filenamesToDelete)

        places.removeAll { $0.id == id }
        routes.removeAll { routeIdsToDelete.contains($0.id) }
        climbings.removeAll { $0.placeId == id || routeIdsToDelete.contains($0.routeId) }

        save()
    }


    func addRoute(placeId: UUID, name: String, grade: ClimbingGrade, kind: RouteKind, details: String) {
        let route = Route(placeId: placeId, name: name, grade: grade, kind: kind, details: details)
        routes.append(route)
        routes.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func updateRoute(_ route: Route) {
        guard let idx = routes.firstIndex(where: { $0.id == route.id }) else { return }
        routes[idx] = route
        routes.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func deleteRoute(id: UUID) {
        let filenamesToDelete = climbings
            .filter { $0.routeId == id }
            .flatMap { $0.photos.map(\.filename) }

        photoStorage.delete(filenames: filenamesToDelete)

        routes.removeAll { $0.id == id }
        climbings.removeAll { $0.routeId == id }

        save()
    }

    func addClimbing(
        date: Date = Date(),
        placeId: UUID,
        routeId: UUID,
        weather: WeatherKind,
        result: ClimbingResult,
        attempts: Int,
        mood: MoodKind,
        uiImages: [UIImage] = [],
        photoData: [Data] = [],
        jpegCompressionQuality: CGFloat = 0.82,
        note: String
    ) {
        let photoModels = savePhotosToDisk(
            uiImages: uiImages,
            photoData: photoData,
            jpegCompressionQuality: jpegCompressionQuality
        )

        let climbing = Climbing(
            date: date,
            placeId: placeId,
            routeId: routeId,
            weather: weather,
            result: result,
            attempts: attempts,
            mood: mood,
            photos: photoModels,
            note: note
        )

        climbings.append(climbing)
        save()
    }

    func updateClimbing(_ climbing: Climbing) {
        guard let idx = climbings.firstIndex(where: { $0.id == climbing.id }) else { return }
        climbings[idx] = climbing
        save()
    }


    func replaceClimbingPhotos(
        climbingId: UUID,
        uiImages: [UIImage] = [],
        photoData: [Data] = [],
        jpegCompressionQuality: CGFloat = 0.82
    ) {
        guard let idx = climbings.firstIndex(where: { $0.id == climbingId }) else { return }

        let oldFilenames = climbings[idx].photos.map(\.filename)
        photoStorage.delete(filenames: oldFilenames)

        let newPhotoModels = savePhotosToDisk(
            uiImages: uiImages,
            photoData: photoData,
            jpegCompressionQuality: jpegCompressionQuality
        )

        climbings[idx].photos = newPhotoModels
        save()
    }

    func deleteClimbing(id: UUID) {
        if let item = climbings.first(where: { $0.id == id }) {
            let filenames = item.photos.map(\.filename)
            photoStorage.delete(filenames: filenames)
        }

        climbings.removeAll { $0.id == id }
        save()
    }

    
    private func savePhotosToDisk(
        uiImages: [UIImage],
        photoData: [Data],
        jpegCompressionQuality: CGFloat
    ) -> [ClimbingPhoto] {
        var allJPEG: [Data] = []
        allJPEG.reserveCapacity(uiImages.count + photoData.count)

        for image in uiImages {
            if let jpeg = image.jpegData(compressionQuality: jpegCompressionQuality) {
                allJPEG.append(jpeg)
            }
        }

        for data in photoData {
            guard let image = UIImage(data: data) else {
                print("⚠️ Skipped one photo: cannot decode data to UIImage.")
                continue
            }
            guard let jpeg = image.jpegData(compressionQuality: jpegCompressionQuality) else {
                print("⚠️ Skipped one photo: cannot encode UIImage to JPEG.")
                continue
            }
            allJPEG.append(jpeg)
        }

        let limited = Array(allJPEG.prefix(3))

        var photoModels: [ClimbingPhoto] = []
        photoModels.reserveCapacity(limited.count)

        for jpeg in limited {
            do {
                let filename = try photoStorage.saveJPEGData(jpeg)
                photoModels.append(ClimbingPhoto(filename: filename))
            } catch {
                print("❌ Photo save error:", error)
            }
        }

        return photoModels
    }


    private struct Payload: Codable {
        var schemaVersion: Int
        var places: [Place]
        var routes: [Route]
        var climbings: [Climbing]
    }

    private func save() {
        do {
            let payload = Payload(schemaVersion: 3, places: places, routes: routes, climbings: climbings)
            let data = try encoder.encode(payload)
            userDefaults.set(data, forKey: payloadKey)
        } catch {
            print("❌ Save JSON error:", error)
        }
    }

    private func load() {
        guard let data = userDefaults.data(forKey: payloadKey) else { return }
        do {
            let payload = try decoder.decode(Payload.self, from: data)
            self.places = payload.places
            self.routes = payload.routes
            self.climbings = payload.climbings
        } catch {
            print("❌ Load JSON error:", error)
        }
    }
}
