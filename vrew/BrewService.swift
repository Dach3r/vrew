import Foundation
import SwiftUI

enum ServiceStatus: String, Equatable {
    case started = "started"
    case stopped = "stopped"
    case error   = "error"
    case unknown = "unknown"

    var color: Color {
        switch self {
        case .started: return .green
        case .stopped: return Color(nsColor: .secondaryLabelColor)
        case .error:   return .yellow
        case .unknown: return .gray
        }
    }

    var systemImage: String {
        switch self {
        case .started: return "circle.fill"
        case .stopped: return "circle"
        case .error:   return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var label: String {
        switch self {
        case .started: return "Running"
        case .stopped: return "Stopped"
        case .error:   return "Error"
        case .unknown: return "Unknown"
        }
    }
}

struct BrewService: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var status: ServiceStatus
    let user: String
    let plist: String

    init?(rawLine: String) {
        let columns = rawLine
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        guard columns.count >= 2 else { return nil }

        name   = columns[0]
        status = ServiceStatus(rawValue: columns[1].lowercased()) ?? .unknown
        user   = columns.count >= 3 ? columns[2] : ""
        plist  = columns.count >= 4 ? columns[3] : ""
    }
    
    init(name: String, status: ServiceStatus, user: String = "", plist: String = "") {
        self.name   = name
        self.status = status
        self.user   = user
        self.plist  = plist
    }

    static func == (lhs: BrewService, rhs: BrewService) -> Bool {
        lhs.name == rhs.name && lhs.status == rhs.status
    }
}
