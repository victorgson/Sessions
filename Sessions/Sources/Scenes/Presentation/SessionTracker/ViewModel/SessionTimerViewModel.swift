import Foundation
import Observation
import Tracking

@MainActor
@Observable
final class SessionTimerViewModel: ActionTracking {
    struct StopResult {
        let startDate: Date
        let duration: TimeInterval
    }

    let trackerDispatcher: TrackerDispatcher
    let hapticBox: HapticBox
    let liveActivityController: any SessionLiveActivityControlling
    let timerConfigurationStore: any SessionTimerConfigurationStoring

    var onSessionStopped: ((StopResult) -> Void)?

    var timerConfiguration: SessionTimerConfiguration {
        didSet {
            guard timerConfiguration != oldValue else { return }
            timerConfigurationStore.save(timerConfiguration)
        }
    }

    private(set) var sessionStartDate: Date?
    @ObservationIgnored var sessionTimerModeInUse: SessionTimerConfiguration.Mode?
    @ObservationIgnored var pomodoroContext: PomodoroSessionContext?
    @ObservationIgnored var pomodoroPhaseMonitorTask: Task<Void, Never>?
    @ObservationIgnored var lastReportedPomodoroPhase: PomodoroPhaseType?

    init(
        trackerDispatcher: TrackerDispatcher,
        hapticBox: HapticBox,
        liveActivityController: any SessionLiveActivityControlling,
        timerConfigurationStore: any SessionTimerConfigurationStoring
    ) {
        self.trackerDispatcher = trackerDispatcher
        self.hapticBox = hapticBox
        self.liveActivityController = liveActivityController
        self.timerConfigurationStore = timerConfigurationStore
        self.timerConfiguration = timerConfigurationStore.load()
    }

    var isTimerRunning: Bool {
        sessionStartDate != nil
    }

    var activeSessionStartDate: Date? {
        sessionStartDate
    }

    func startSession(now: Date = .now) {
        guard sessionStartDate == nil else { return }
        sessionStartDate = now
        sessionTimerModeInUse = timerConfiguration.mode
        configurePomodoroContextIfNeeded(startDate: now)
        trackAction(TrackingEvent.SessionTracker.Action(value: .startSession))
        hapticBox.triggerImpact(style: DefaultHapticBox.Impact.medium)
        Task {
            let snapshot = timerSnapshot(at: now, reportPhaseChange: false) ?? SessionTimerSnapshot(
                title: "Session Running",
                valueText: "00:00:00",
                detailText: nil,
                countsDown: false,
                timerRange: now...Date.distantFuture,
                phaseType: nil
            )
            lastReportedPomodoroPhase = snapshot.phaseType
            await liveActivityController.startLiveActivity(startDate: now, state: snapshot.liveActivityState)
        }
    }

    func stopSession(now: Date = .now) {
        guard let start = sessionStartDate else { return }
        trackAction(TrackingEvent.SessionTracker.Action(value: .stopSession))
        let duration = sessionDuration(until: now, from: start)
        sessionStartDate = nil
        sessionTimerModeInUse = nil
        pomodoroContext = nil
        pomodoroPhaseMonitorTask?.cancel()
        pomodoroPhaseMonitorTask = nil
        lastReportedPomodoroPhase = nil
        Task {
            await liveActivityController.endLiveActivity()
        }

        guard duration > 0 else { return }
        onSessionStopped?(StopResult(startDate: start, duration: duration))
        trackAction(TrackingEvent.SessionTracker.Action(value: .openActivityDraft(.new)))
        hapticBox.triggerImpact(style: DefaultHapticBox.Impact.light)
    }

    func timerSnapshot(at date: Date, reportPhaseChange: Bool = true) -> SessionTimerSnapshot? {
        guard let start = sessionStartDate else { return nil }

        let mode = sessionTimerModeInUse ?? timerConfiguration.mode
        let snapshot: SessionTimerSnapshot

        switch mode {
        case .continuous:
            snapshot = continuousSnapshot(start: start, now: date)
        case .pomodoro(let focusMinutes, let breakMinutes):
            let context: PomodoroSessionContext
            if let existingContext = pomodoroContext {
                context = existingContext
            } else {
                let newContext = makePomodoroContext(
                    startDate: start,
                    focusMinutes: focusMinutes,
                    breakMinutes: breakMinutes
                )
                pomodoroContext = newContext
                startPomodoroPhaseMonitor()
                context = newContext
            }
            snapshot = pomodoroSnapshot(context: context, now: date)
        }

        if reportPhaseChange {
            handleLiveActivityUpdateIfNeeded(for: snapshot)
        }

        return snapshot
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    func elapsedTimeString(now: Date = .now) -> String {
        guard let start = sessionStartDate else { return "00:00:00" }
        let interval = now.timeIntervalSince(start)
        return formattedTimer(interval)
    }

    func formattedTimer(_ interval: TimeInterval) -> String {
        let clampedInterval = max(interval, 0)
        let totalSeconds = Int(clampedInterval.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func formattedCountdown(_ interval: TimeInterval) -> String {
        let clampedInterval = max(interval, 0)
        let totalSeconds = Int(clampedInterval.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%02d:%02d:%02d", hours, remainingMinutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

private extension SessionTimerViewModel {
    func continuousSnapshot(start: Date, now: Date) -> SessionTimerSnapshot {
        SessionTimerSnapshot(
            title: "Session Running",
            valueText: formattedTimer(now.timeIntervalSince(start)),
            detailText: nil,
            countsDown: false,
            timerRange: start...Date.distantFuture,
            phaseType: nil
        )
    }

    func pomodoroSnapshot(context: PomodoroSessionContext, now: Date) -> SessionTimerSnapshot {
        let phase = context.phase(at: now)
        let remaining = max(phase.endDate.timeIntervalSince(now), 0)
        return SessionTimerSnapshot(
            title: phase.type.title,
            valueText: formattedCountdown(remaining),
            detailText: activePomodoroSummaryText(),
            countsDown: true,
            timerRange: phase.startDate...phase.endDate,
            phaseType: phase.type
        )
    }

    func handleLiveActivityUpdateIfNeeded(for snapshot: SessionTimerSnapshot) {
        guard let phaseType = snapshot.phaseType else { return }
        guard phaseType != lastReportedPomodoroPhase else { return }
        lastReportedPomodoroPhase = phaseType
        Task {
            await liveActivityController.updateLiveActivity(with: snapshot.liveActivityState)
        }
    }

    func configurePomodoroContextIfNeeded(startDate: Date) {
        guard case .pomodoro(let focusMinutes, let breakMinutes) = sessionTimerModeInUse else {
            pomodoroContext = nil
            pomodoroPhaseMonitorTask?.cancel()
            pomodoroPhaseMonitorTask = nil
            return
        }

        pomodoroContext = PomodoroSessionContext(
            startDate: startDate,
            focusDuration: TimeInterval(max(focusMinutes, 0) * 60),
            breakDuration: TimeInterval(max(breakMinutes, 0) * 60)
        )
        startPomodoroPhaseMonitor()
    }

    func startPomodoroPhaseMonitor() {
        pomodoroPhaseMonitorTask?.cancel()
        guard pomodoroContext != nil else { return }

        pomodoroPhaseMonitorTask = Task { [weak self] in
            await self?.runPomodoroPhaseMonitor()
        }
    }

    @MainActor
    func runPomodoroPhaseMonitor() async {
        guard let context = pomodoroContext else { return }

        while !Task.isCancelled {
            guard sessionStartDate != nil else { return }
            let now = Date()
            let phase = context.phase(at: now)
            let rawDelay = phase.endDate.timeIntervalSince(now)
            let delay = max(rawDelay, 0)
            let sleepDuration = max(delay, 0.1)
            do {
                try await Task.sleep(nanoseconds: UInt64(sleepDuration * 1_000_000_000))
            } catch {
                return
            }

            if Task.isCancelled { return }
            guard sessionStartDate != nil else { return }
            _ = timerSnapshot(at: Date(), reportPhaseChange: true)
        }
    }

    func activePomodoroSummaryText() -> String? {
        guard case .pomodoro(let focusMinutes, let breakMinutes) =
            sessionTimerModeInUse ?? timerConfiguration.mode else {
            return nil
        }
        let configuration = SessionTimerConfiguration(mode: .pomodoro(
            focusMinutes: focusMinutes,
            breakMinutes: breakMinutes
        ))
        return configuration.summaryText
    }

    func makePomodoroContext(startDate: Date, focusMinutes: Int, breakMinutes: Int) -> PomodoroSessionContext {
        PomodoroSessionContext(
            startDate: startDate,
            focusDuration: TimeInterval(max(focusMinutes, 0) * 60),
            breakDuration: TimeInterval(max(breakMinutes, 0) * 60)
        )
    }

    func sessionDuration(until date: Date, from start: Date) -> TimeInterval {
        if case .pomodoro = sessionTimerModeInUse, let context = pomodoroContext {
            return context.focusTimeElapsed(until: date)
        } else {
            return date.timeIntervalSince(start)
        }
    }
}

struct SessionTimerSnapshot {
    let title: String
    let valueText: String
    let detailText: String?
    let countsDown: Bool
    let timerRange: ClosedRange<Date>
    let phaseType: PomodoroPhaseType?

    var liveActivityState: SessionLiveActivityDisplayState {
        SessionLiveActivityDisplayState(
            timerRange: timerRange,
            countsDown: countsDown,
            title: title,
            detail: detailText
        )
    }
}

enum PomodoroPhaseType {
    case focus
    case rest

    var title: String {
        switch self {
        case .focus:
            return "Focus"
        case .rest:
            return "Break"
        }
    }
}

struct PomodoroPhase {
    let type: PomodoroPhaseType
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}

struct PomodoroSessionContext {
    let startDate: Date
    let focusDuration: TimeInterval
    let breakDuration: TimeInterval

    private var cycleDuration: TimeInterval {
        let total = focusDuration + breakDuration
        return total > 0 ? total : .leastNonzeroMagnitude
    }

    func phase(at date: Date) -> PomodoroPhase {
        let elapsed = max(date.timeIntervalSince(startDate), 0)
        let completedCycles = floor(elapsed / cycleDuration)
        let cycleStart = startDate.addingTimeInterval(completedCycles * cycleDuration)
        let positionInCycle = elapsed - (completedCycles * cycleDuration)

        if focusDuration <= 0 {
            let phaseStart = cycleStart
            let end = phaseStart.addingTimeInterval(max(breakDuration, 0))
            return PomodoroPhase(type: .rest, startDate: phaseStart, endDate: end)
        }

        if breakDuration <= 0 || positionInCycle < focusDuration {
            let phaseStart = cycleStart
            let end = phaseStart.addingTimeInterval(focusDuration)
            return PomodoroPhase(type: .focus, startDate: phaseStart, endDate: end)
        } else {
            let phaseStart = cycleStart.addingTimeInterval(focusDuration)
            let end = phaseStart.addingTimeInterval(breakDuration)
            return PomodoroPhase(type: .rest, startDate: phaseStart, endDate: end)
        }
    }

    func focusTimeElapsed(until date: Date) -> TimeInterval {
        guard focusDuration > 0 else { return 0 }
        let elapsed = max(date.timeIntervalSince(startDate), 0)
        let completedCycles = floor(elapsed / cycleDuration)
        let remainder = elapsed - (completedCycles * cycleDuration)
        let focusPortion = min(remainder, focusDuration)
        return (completedCycles * focusDuration) + focusPortion
    }
}
