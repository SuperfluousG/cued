import Foundation

struct CuedPaths: Equatable {
    let root: URL
    let decks: URL
    let skills: URL
    let openAISkill: URL
    let claudeSkillPackage: URL

    static var live: CuedPaths {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let root = home.appendingPathComponent("Documents/Cued", isDirectory: true)
        return CuedPaths(
            root: root,
            decks: root.appendingPathComponent("Decks", isDirectory: true),
            skills: root.appendingPathComponent("Skills", isDirectory: true),
            openAISkill: home.appendingPathComponent(".agents/skills/make-cued-deck", isDirectory: true),
            claudeSkillPackage: root.appendingPathComponent("Skills/make-cued-deck-claude.zip")
        )
    }
}

struct SupportStatus: Equatable {
    var openAISkillInstalled = false
    var claudePackageReady = false
    var error: String?
}

enum SupportInstallerError: LocalizedError {
    case supportFilesMissing

    var errorDescription: String? {
        "Cued's bundled support files are missing. Reinstall the application."
    }
}

enum SupportInstaller {
    static func prepare(paths: CuedPaths, resources: URL? = Bundle.main.resourceURL) throws -> SupportStatus {
        let manager = FileManager.default
        try manager.createDirectory(at: paths.decks, withIntermediateDirectories: true)
        try manager.createDirectory(at: paths.skills, withIntermediateDirectories: true)

        guard let support = resources?.appendingPathComponent("CuedSupport", isDirectory: true) else {
            throw SupportInstallerError.supportFilesMissing
        }
        let skillSource = support.appendingPathComponent("make-cued-deck", isDirectory: true)
        let claudeSource = support.appendingPathComponent("make-cued-deck-claude.zip")
        guard manager.fileExists(atPath: skillSource.appendingPathComponent("SKILL.md").path),
              manager.fileExists(atPath: claudeSource.path) else {
            throw SupportInstallerError.supportFilesMissing
        }

        try manager.createDirectory(at: paths.openAISkill.deletingLastPathComponent(), withIntermediateDirectories: true)
        if manager.fileExists(atPath: paths.openAISkill.path) {
            try manager.removeItem(at: paths.openAISkill)
        }
        try manager.copyItem(at: skillSource, to: paths.openAISkill)

        if manager.fileExists(atPath: paths.claudeSkillPackage.path) {
            try manager.removeItem(at: paths.claudeSkillPackage)
        }
        try manager.copyItem(at: claudeSource, to: paths.claudeSkillPackage)

        return SupportStatus(openAISkillInstalled: true, claudePackageReady: true, error: nil)
    }
}
