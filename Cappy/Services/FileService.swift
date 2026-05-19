import AppKit
import UniformTypeIdentifiers

enum FileService {
    static var saveDirectory: URL {
        let pictures = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures")
            .appendingPathComponent("Cappy")
        return pictures
    }

    static func ensureSaveDirectory() throws {
        if !FileManager.default.fileExists(atPath: saveDirectory.path) {
            try FileManager.default.createDirectory(
                at: saveDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    static func savePNG(image: CGImage, filename: String) throws -> URL {
        try ensureSaveDirectory()
        let fileURL = saveDirectory.appendingPathComponent(filename)

        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw FileError.destinationCreationFailed
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            if !hasSufficientDiskSpace(fileURL) {
                throw FileError.insufficientDiskSpace
            }
            throw FileError.writeFailed
        }

        return fileURL
    }

    static func overwritePNG(image: CGImage, at url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw FileError.destinationCreationFailed
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw FileError.writeFailed
        }
    }

    private static func hasSufficientDiskSpace(_ url: URL) -> Bool {
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let capacity = values.volumeAvailableCapacity {
                return capacity > 10 * 1024 * 1024
            }
        } catch {}
        return true
    }

    static func hasSaveDirectoryDiskSpace() -> Bool {
        return hasSufficientDiskSpace(saveDirectory)
    }
}

enum FileError: LocalizedError {
    case destinationCreationFailed
    case writeFailed
    case insufficientDiskSpace

    var errorDescription: String? {
        switch self {
        case .destinationCreationFailed:
            return "Could not create the output file."
        case .writeFailed:
            return "Failed to write PNG data to disk."
        case .insufficientDiskSpace:
            return "Not enough disk space to save the screenshot."
        }
    }
}
