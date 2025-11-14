import Observation

@MainActor
@Observable
final class TimerConfigurationSheetViewModel {
    private let timerViewModel: SessionTimerViewModel

    init(timerViewModel: SessionTimerViewModel) {
        self.timerViewModel = timerViewModel
    }

    var configuration: SessionTimerConfiguration {
        get { timerViewModel.timerConfiguration }
        set { timerViewModel.timerConfiguration = newValue }
    }
}
