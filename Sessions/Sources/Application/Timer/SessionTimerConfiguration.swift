import Foundation

struct SessionTimerConfiguration: Codable, Equatable {
    enum Mode: Equatable {
        case continuous
        case pomodoro(focusMinutes: Int, breakMinutes: Int)
    }

    var mode: Mode

    init(mode: Mode = .continuous) {
        self.mode = mode
    }
}

extension SessionTimerConfiguration {
    static let `default` = SessionTimerConfiguration(mode: .continuous)

    var summaryText: String {
        switch mode {
        case .continuous:
            return "Continuous timer"
        case .pomodoro(let focus, let rest):
            return "Pomodoro • \(focus)m focus, \(rest)m break"
        }
    }

    var defaultPomodoroFocusMinutes: Int {
        switch mode {
        case .continuous:
            return 25
        case .pomodoro(let focus, _):
            return focus
        }
    }

    var defaultPomodoroBreakMinutes: Int {
        switch mode {
        case .continuous:
            return 5
        case .pomodoro(_, let rest):
            return rest
        }
    }
}

extension SessionTimerConfiguration.Mode: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case focusMinutes
        case breakMinutes
    }

    private enum ModeType: String, Codable {
        case continuous
        case pomodoro
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ModeType.self, forKey: .type)

        switch type {
        case .continuous:
            self = .continuous
        case .pomodoro:
            let focus = try container.decode(Int.self, forKey: .focusMinutes)
            let rest = try container.decode(Int.self, forKey: .breakMinutes)
            self = .pomodoro(focusMinutes: focus, breakMinutes: rest)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .continuous:
            try container.encode(ModeType.continuous, forKey: .type)
        case .pomodoro(let focus, let rest):
            try container.encode(ModeType.pomodoro, forKey: .type)
            try container.encode(focus, forKey: .focusMinutes)
            try container.encode(rest, forKey: .breakMinutes)
        }
    }
}
