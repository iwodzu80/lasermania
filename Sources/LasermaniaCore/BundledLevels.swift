import Foundation

public struct LevelManifest: Codable, Sendable {
    public let levels: [String]
}

public enum BundledLevelsError: Error, CustomStringConvertible {
    case manifestNotFound
    case levelNotFound(String)

    public var description: String {
        switch self {
        case .manifestNotFound:
            return "Could not find Resources/Levels/manifest.json in the LasermaniaCore bundle."
        case .levelNotFound(let id):
            return "Could not find Resources/Levels/\(id).json in the LasermaniaCore bundle."
        }
    }
}

public enum BundledLevels {
    public static func all() throws -> [LevelDefinition] {
        guard let manifestURL = Bundle.module.url(forResource: "manifest", withExtension: "json", subdirectory: "Levels") else {
            throw BundledLevelsError.manifestNotFound
        }
        let manifest = try JSONDecoder().decode(LevelManifest.self, from: Data(contentsOf: manifestURL))

        return try manifest.levels.map { id in
            guard let url = Bundle.module.url(forResource: id, withExtension: "json", subdirectory: "Levels") else {
                throw BundledLevelsError.levelNotFound(id)
            }
            return try JSONDecoder().decode(LevelDefinition.self, from: Data(contentsOf: url))
        }
    }
}
