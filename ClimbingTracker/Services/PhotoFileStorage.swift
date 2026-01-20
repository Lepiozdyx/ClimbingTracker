import Foundation

final class PhotoFileStorage {
    static let shared = PhotoFileStorage()

    private let fileManager = FileManager.default
    private let folderName = "ClimbingPhotos"

    private init() {}

    private func photosDirectoryURL() throws -> URL {
        let caches = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let dir = caches.appendingPathComponent(folderName, isDirectory: true)

        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir
    }

    func saveJPEGData(_ data: Data) throws -> String {
        let filename = UUID().uuidString + ".jpg"
        let url = try photosDirectoryURL().appendingPathComponent(filename, isDirectory: false)
        try data.write(to: url, options: [.atomic])
        return filename
    }

    func loadData(filename: String) throws -> Data {
        let url = try photosDirectoryURL().appendingPathComponent(filename, isDirectory: false)
        return try Data(contentsOf: url)
    }

    func fileURL(filename: String) throws -> URL {
        try photosDirectoryURL().appendingPathComponent(filename, isDirectory: false)
    }

    func delete(filename: String) {
        do {
            let url = try photosDirectoryURL().appendingPathComponent(filename, isDirectory: false)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        } catch {
            print("❌ Photo delete error:", error)
        }
    }

    func delete(filenames: [String]) {
        for name in filenames {
            delete(filename: name)
        }
    }
}
