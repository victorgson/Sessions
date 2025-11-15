import Foundation
import Observation
import Tracking

@MainActor
@Observable
final class SessionTrackerViewModel {
    let loadObjectivesUseCase: LoadObjectivesUseCase
    let loadActivitiesUseCase: LoadActivitiesUseCase
    let upsertObjectiveUseCase: UpsertObjectiveUseCase
    let createObjectiveUseCase: CreateObjectiveUseCase
    let removeObjectiveUseCase: RemoveObjectiveUseCase
    let recordActivityUseCase: RecordActivityUseCase
    let updateActivityUseCase: UpdateActivityUseCase
    let removeActivityUseCase: RemoveActivityUseCase
    let promptAppStoreRatingUseCase: PromptAppStoreRatingUseCase
    let trackerDispatcher: TrackerDispatcher
    let hapticBox: HapticBox
    let liveActivityController: SessionLiveActivityControlling
    let subscriptionStatusProvider: SubscriptionStatusProviding
    let timerConfigurationStore: SessionTimerConfigurationStoring
    private let userDefaults: UserDefaults
    private static let initialPaywallDefaultsKey = "hasPresentedInitialPaywall"
    var activityDraft: ActivityDraft?
    private(set) var shouldPresentInitialPaywall: Bool

    @ObservationIgnored private var cachedObjectivesViewModel: ObjectivesOverviewViewModel?
    @ObservationIgnored private var cachedTimerViewModel: SessionTimerViewModel?
    @ObservationIgnored private var cachedRecentSessionsViewModel: RecentSessionsViewModel?
    @ObservationIgnored private var cachedSettingsViewModel: SettingsViewModel?
    @ObservationIgnored private var cachedTimerConfigurationSheetViewModel: TimerConfigurationSheetViewModel?
    @ObservationIgnored private var cachedActivityLinkSheetCoordinator: ActivityLinkSheetCoordinator?
    @ObservationIgnored private var cachedArchivedObjectivesViewModel: ArchivedObjectivesViewModel?

    private let defaultSectionOrder: [HomeSectionType] = [.objectives, .timer, .activityFeed]

    var objectivesViewModel: ObjectivesOverviewViewModel {
        if let cachedObjectivesViewModel { return cachedObjectivesViewModel }
        let viewModel = ObjectivesOverviewViewModel(
            loadObjectivesUseCase: loadObjectivesUseCase,
            upsertObjectiveUseCase: upsertObjectiveUseCase,
            createObjectiveUseCase: createObjectiveUseCase,
            removeObjectiveUseCase: removeObjectiveUseCase,
            hapticBox: hapticBox,
            cleanupHandler: { [weak self] objectiveID in
                self?.cleanupStateForObjectiveRemoval(objectiveID)
            },
            reloadActivitiesHandler: { [weak self] in
                guard let self else { return }
                await self.reloadActivitiesFromStore()
            }
        )
        cachedObjectivesViewModel = viewModel
        return viewModel
    }

    var timerViewModel: SessionTimerViewModel {
        if let cachedTimerViewModel { return cachedTimerViewModel }
        let viewModel = SessionTimerViewModel(
            trackerDispatcher: trackerDispatcher,
            hapticBox: hapticBox,
            liveActivityController: liveActivityController,
            timerConfigurationStore: timerConfigurationStore
        )
        viewModel.onSessionStopped = { [weak self] result in
            self?.handleSessionStopped(result)
        }
        cachedTimerViewModel = viewModel
        return viewModel
    }

    var recentSessionsViewModel: RecentSessionsViewModel {
        if let cachedRecentSessionsViewModel { return cachedRecentSessionsViewModel }
        let viewModel = RecentSessionsViewModel(
            loadActivitiesUseCase: loadActivitiesUseCase,
            removeActivityUseCase: removeActivityUseCase,
            trackerDispatcher: trackerDispatcher,
            hapticBox: hapticBox,
            objectiveAdjustmentHandler: { [weak self] objectiveID, allocations, adding in
                self?.applyTimeAllocations(allocations, to: objectiveID, adding: adding)
            }
        )
        cachedRecentSessionsViewModel = viewModel
        return viewModel
    }

    var insightsViewModel: InsightsViewModel {
        InsightsViewModel(
            activities: recentSessionsViewModel.activities,
            objectives: objectivesViewModel.objectives,
            durationFormatter: { [timerViewModel] duration in
                timerViewModel.formattedDuration(duration)
            }
        )
    }

    var settingsViewModel: SettingsViewModel {
        if let cachedSettingsViewModel { return cachedSettingsViewModel }
        let viewModel = SettingsViewModel(subscriptionStatusProvider: subscriptionStatusProvider)
        cachedSettingsViewModel = viewModel
        return viewModel
    }

    var timerConfigurationSheetViewModel: TimerConfigurationSheetViewModel {
        if let cachedTimerConfigurationSheetViewModel { return cachedTimerConfigurationSheetViewModel }
        let viewModel = TimerConfigurationSheetViewModel(timerViewModel: timerViewModel)
        cachedTimerConfigurationSheetViewModel = viewModel
        return viewModel
    }

    private var activityLinkSheetCoordinator: ActivityLinkSheetCoordinator {
        if let cachedActivityLinkSheetCoordinator { return cachedActivityLinkSheetCoordinator }
        let coordinator = ActivityLinkSheetCoordinator(sessionTrackerViewModel: self)
        cachedActivityLinkSheetCoordinator = coordinator
        return coordinator
    }

    var archivedObjectivesViewModel: ArchivedObjectivesViewModel {
        if let cachedArchivedObjectivesViewModel { return cachedArchivedObjectivesViewModel }
        let viewModel = ArchivedObjectivesViewModel(objectivesViewModel: objectivesViewModel)
        cachedArchivedObjectivesViewModel = viewModel
        return viewModel
    }

    enum HomeSection {
        case objectives(ObjectivesOverviewViewModel)
        case timer(SessionTimerViewModel)
        case activityFeed(RecentSessionsViewModel)
    }

    enum HomeSectionType {
        case objectives
        case timer
        case activityFeed
    }

    enum SheetDestination {
        case settings(SettingsViewModel)
        case timerConfiguration(TimerConfigurationSheetViewModel)
        case activityLink(ActivityLinkSheetCoordinator)
        case archivedObjectives(ArchivedObjectivesViewModel)
    }

    enum SheetType {
        case settings
        case timerConfiguration
        case activityLink
        case archivedObjectives
    }

    var homeSections: [HomeSection] {
        createSections(from: defaultSectionOrder)
    }

    func createSections(from orderedTypes: [HomeSectionType]) -> [HomeSection] {
        orderedTypes.compactMap { section in
            switch section {
            case .objectives:
                return .objectives(objectivesViewModel)
            case .timer:
                return .timer(timerViewModel)
            case .activityFeed:
                return .activityFeed(recentSessionsViewModel)
            }
        }
    }

    func sheet(for type: SheetType) -> SheetDestination? {
        switch type {
        case .settings:
            return .settings(settingsViewModel)
        case .timerConfiguration:
            return .timerConfiguration(timerConfigurationSheetViewModel)
        case .activityLink:
            guard activityDraft != nil else { return nil }
            return .activityLink(activityLinkSheetCoordinator)
        case .archivedObjectives:
            return .archivedObjectives(archivedObjectivesViewModel)
        }
    }

    var objectives: [Objective] {
        objectivesViewModel.objectives
    }

    var activeObjectives: [Objective] {
        objectivesViewModel.activeObjectives
    }

    var archivedObjectives: [Objective] {
        objectivesViewModel.archivedObjectives
    }

    var hasArchivedObjectives: Bool {
        objectivesViewModel.hasArchivedObjectives
    }

    var activities: [Activity] {
        get { recentSessionsViewModel.activities }
        set { recentSessionsViewModel.activities = newValue }
    }

    var timerConfiguration: SessionTimerConfiguration {
        get { timerViewModel.timerConfiguration }
        set { timerViewModel.timerConfiguration = newValue }
    }

    var isTimerRunning: Bool {
        timerViewModel.isTimerRunning
    }

    var activeSessionStartDate: Date? {
        timerViewModel.activeSessionStartDate
    }

    func startSession(now: Date = .now) {
        timerViewModel.startSession(now: now)
    }

    func stopSession(now: Date = .now) {
        timerViewModel.stopSession(now: now)
    }

    func timerSnapshot(at date: Date, reportPhaseChange: Bool = true) -> SessionTimerSnapshot? {
        timerViewModel.timerSnapshot(at: date, reportPhaseChange: reportPhaseChange)
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        timerViewModel.formattedDuration(duration)
    }
    init(
        loadObjectivesUseCase: LoadObjectivesUseCase,
        loadActivitiesUseCase: LoadActivitiesUseCase,
        upsertObjectiveUseCase: UpsertObjectiveUseCase,
        createObjectiveUseCase: CreateObjectiveUseCase,
        removeObjectiveUseCase: RemoveObjectiveUseCase,
        recordActivityUseCase: RecordActivityUseCase,
        updateActivityUseCase: UpdateActivityUseCase,
        removeActivityUseCase: RemoveActivityUseCase,
        promptAppStoreRatingUseCase: PromptAppStoreRatingUseCase,
        trackerDispatcher: TrackerDispatcher,
        hapticBox: HapticBox,
        liveActivityController: SessionLiveActivityControlling,
        subscriptionStatusProvider: SubscriptionStatusProviding,
        timerConfigurationStore: SessionTimerConfigurationStoring,
        userDefaults: UserDefaults = .standard
    ) {
        self.loadObjectivesUseCase = loadObjectivesUseCase
        self.loadActivitiesUseCase = loadActivitiesUseCase
        self.upsertObjectiveUseCase = upsertObjectiveUseCase
        self.createObjectiveUseCase = createObjectiveUseCase
        self.removeObjectiveUseCase = removeObjectiveUseCase
        self.recordActivityUseCase = recordActivityUseCase
        self.updateActivityUseCase = updateActivityUseCase
        self.removeActivityUseCase = removeActivityUseCase
        self.promptAppStoreRatingUseCase = promptAppStoreRatingUseCase
        self.trackerDispatcher = trackerDispatcher
        self.hapticBox = hapticBox
        self.liveActivityController = liveActivityController
        self.subscriptionStatusProvider = subscriptionStatusProvider
        self.timerConfigurationStore = timerConfigurationStore
        self.userDefaults = userDefaults
        self.shouldPresentInitialPaywall = !userDefaults.bool(
            forKey: Self.initialPaywallDefaultsKey
        )

        Task {
            await loadInitialData()
        }
    }

    func markInitialPaywallPresentedIfNeeded() {
        guard shouldPresentInitialPaywall else { return }
        if !userDefaults.bool(forKey: Self.initialPaywallDefaultsKey) {
            userDefaults.set(true, forKey: Self.initialPaywallDefaultsKey)
        }
    }
}

extension SessionTrackerViewModel.HomeSection: Identifiable {
    var id: String {
        switch self {
        case .objectives:
            return "objectives"
        case .timer:
            return "timer"
        case .activityFeed:
            return "activity-feed"
        }
    }
}

extension SessionTrackerViewModel: ActionTracking, PageTracking {
    var pageViewEvent: TrackablePageEvent {
        TrackingEvent.SessionTracker.Page()
    }
}

// MARK: - Objective helpers

private extension SessionTrackerViewModel {
    func cleanupStateForObjectiveRemoval(_ id: UUID) {
        for index in recentSessionsViewModel.activities.indices {
            guard recentSessionsViewModel.activities[index].linkedObjectiveID == id else { continue }
            recentSessionsViewModel.activities[index].linkedObjectiveID = nil
            recentSessionsViewModel.activities[index].keyResultAllocations.removeAll()
        }

        if var draft = activityDraft, draft.selectedObjectiveID == id {
            draft.selectedObjectiveID = nil
            draft.selectedTimeAllocations = [:]
            draft.quantityValues = [:]
            activityDraft = draft
        }
    }

    func reloadActivitiesFromStore() async {
        await recentSessionsViewModel.loadActivities()
    }

    func handleSessionStopped(_ result: SessionTimerViewModel.StopResult) {
        activityDraft = ActivityDraft(
            originalActivity: nil,
            startedAt: result.startDate,
            duration: result.duration,
            selectedObjectiveID: nil,
            selectedTimeAllocations: [:],
            quantityValues: [:],
            note: "",
            tagsText: ""
        )
    }
}
