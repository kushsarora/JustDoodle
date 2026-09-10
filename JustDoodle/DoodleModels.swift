import SwiftUI
import PencilKit
import Photos
import UIKit

enum AppScreen: Hashable {
    case home
    case revealing
    case drawing
    case result
    case archive
    case challenges
    case settings
}

struct DoodleSession: Codable, Equatable {
    let title: String
    let instruction: String
    let symbol: String
    let duration: Int
    let inks: [DoodleInk]
    let isChallenge: Bool

    static let classic = DoodleSession(
        title: "Classic",
        instruction: "Turn the scribble into anything.",
        symbol: "scribble",
        duration: 180,
        inks: [.black],
        isChallenge: false
    )

    var archiveTitle: String? {
        isChallenge ? title : nil
    }

    var shortDuration: String {
        duration < 60 ? "\(duration) sec" : "\(duration / 60) min"
    }
}

struct ChallengePack: Identifiable {
    let id: String
    let session: DoodleSession
}

enum ChallengeLibrary {
    static let packs = [
        ChallengePack(
            id: "quick-spark",
            session: DoodleSession(
                title: "Quick Spark",
                instruction: "Make it recognizable before time runs out.",
                symbol: "bolt.fill",
                duration: 60,
                inks: [.black],
                isChallenge: true
            )
        ),
        ChallengePack(
            id: "build-it",
            session: DoodleSession(
                title: "Build It",
                instruction: "Invent something useful from the scribble.",
                symbol: "hammer.fill",
                duration: 300,
                inks: [.black, .blue],
                isChallenge: true
            )
        ),
        ChallengePack(
            id: "mood-lines",
            session: DoodleSession(
                title: "Mood Lines",
                instruction: "Draw the feeling your day left behind.",
                symbol: "heart.fill",
                duration: 300,
                inks: [.black, .red],
                isChallenge: true
            )
        ),
        ChallengePack(
            id: "soundtrack-sketch",
            session: DoodleSession(
                title: "Soundtrack Sketch",
                instruction: "Let whatever you hear shape the scribble.",
                symbol: "headphones",
                duration: 600,
                inks: [.black, .blue, .red],
                isChallenge: true
            )
        )
    ]
}

enum DoodleInk: String, Codable, CaseIterable, Identifiable, Equatable {
    case black
    case blue
    case red

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .black:
            return Ink.black
        case .blue:
            return Ink.blue
        case .red:
            return Ink.red
        }
    }

    var uiColor: UIColor {
        switch self {
        case .black:
            return UIColor(red: 0.07, green: 0.07, blue: 0.065, alpha: 1)
        case .blue:
            return UIColor(red: 0.10, green: 0.35, blue: 0.60, alpha: 1)
        case .red:
            return UIColor(red: 0.78, green: 0.16, blue: 0.14, alpha: 1)
        }
    }
}

enum InkPalette: String, CaseIterable, Identifiable {
    case black
    case duo
    case trio

    var id: String { rawValue }

    var label: String {
        switch self {
        case .black: return "Black"
        case .duo: return "Two"
        case .trio: return "Three"
        }
    }

    var inks: [DoodleInk] {
        switch self {
        case .black: return [.black]
        case .duo: return [.black, .blue]
        case .trio: return [.black, .blue, .red]
        }
    }
}

enum ChallengeDuration: Int, CaseIterable, Identifiable {
    case oneMinute = 60
    case threeMinutes = 180
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900

    var id: Int { rawValue }
    var seconds: Int { rawValue }

    var label: String {
        "\(rawValue / 60)m"
    }
}

enum IdeaBank {
    private static let ideas = [
        "airplane", "clock", "anchor", "astronaut", "backpack", "balloon",
        "bicycle", "cupcake", "camera", "castle", "catapult", "cactus",
        "dragon", "drum", "flashlight", "flowerpot", "fountain", "guitar",
        "hamburger", "helicopter", "jellyfish", "kite", "lighthouse", "mailbox",
        "microscope", "monster", "mushroom", "octopus", "pirate", "popcorn",
        "racecar", "rainbow", "robot", "rocket", "sandcastle", "sandwich",
        "seahorse", "sneaker", "spaceship", "submarine", "teapot", "telescope",
        "treehouse", "trophy", "umbrella", "volcano", "whale", "windmill"
    ]

    static func random(excluding excluded: String?) -> String {
        let choices = ideas.filter { $0 != excluded }
        return choices.randomElement() ?? ideas[0]
    }
}

struct DoodleRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let imageFilename: String
    let drawingFilename: String
    let sessionTitle: String?
    let prompt: String?
    var duration: Int? = nil
    var elapsed: Int? = nil
    var scribbleID: String? = nil
    var instruction: String? = nil
    var inks: [DoodleInk]? = nil

    var shareCaption: String {
        let challenge = sessionTitle.map { " Challenge: \($0)." } ?? ""
        return "One scribble, my imagination.\(challenge) Made with Just Doodle. #JustDoodle"
    }

    func matches(search: String) -> Bool {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || [sessionTitle ?? "Classic", prompt ?? "", createdAt.doodleDate]
            .contains { $0.localizedStandardContains(query) }
    }
}

struct SessionClock: Codable, Equatable {
    let duration: Int
    private(set) var deadline: Date?
    private(set) var finishedElapsed: Int?

    init(duration: Int) {
        self.duration = min(900, max(1, duration))
    }

    mutating func start(at now: Date) {
        guard deadline == nil, finishedElapsed == nil else { return }
        deadline = now.addingTimeInterval(TimeInterval(duration))
    }

    func remaining(at now: Date) -> Int {
        if let finishedElapsed { return max(0, duration - finishedElapsed) }
        guard let deadline else { return duration }
        let seconds = min(TimeInterval(duration), max(0, deadline.timeIntervalSince(now)))
        return seconds.isFinite ? Int(ceil(seconds)) : 0
    }

    mutating func finish(at now: Date) {
        guard finishedElapsed == nil else { return }
        finishedElapsed = duration - remaining(at: now)
        deadline = nil
    }
}

struct DoodleDraft: Codable {
    let id: UUID
    let createdAt: Date
    let session: DoodleSession
    let scribble: Scribble
    var drawingData: Data
    var clock: SessionClock
    var ink: DoodleInk
    var idea: String?
    var revision: Int = 0

    var isValid: Bool {
        (1...900).contains(session.duration) && clock.duration == session.duration
            && (clock.finishedElapsed.map { (0...session.duration).contains($0) } ?? true)
            && (clock.deadline == nil || clock.finishedElapsed == nil)
            && (clock.deadline?.timeIntervalSinceReferenceDate.isFinite ?? true)
            && !session.inks.isEmpty && session.inks.contains(ink)
            && scribble.points.count >= 2 && scribble.points.count <= 100
            && scribble.points.allSatisfy { $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y) }
            && (try? PKDrawing(data: drawingData)) != nil
    }
}

enum DoodleTime {
    static func string(_ seconds: Int) -> String {
        String(format: "%d:%02d", max(0, seconds) / 60, max(0, seconds) % 60)
    }
}
