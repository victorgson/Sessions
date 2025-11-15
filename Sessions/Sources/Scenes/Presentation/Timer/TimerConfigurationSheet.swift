import SwiftUI

struct TimerConfigurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: TimerConfigurationSheetViewModel

    private let focusPresets = [15, 20, 25, 30, 40, 50, 60, 90]
    private let breakPresets = [3, 5, 10, 15]

    init(viewModel: TimerConfigurationSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Mode") {
                    Picker("Mode", selection: modeSelectionBinding) {
                        ForEach(TimerModeSelection.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if case .pomodoro = viewModel.configuration.mode {
                    Section("Focus Length") {
                        Text("Choose how long each work block should run.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        presetsGrid(presets: focusPresets, selected: currentFocusMinutes) { minutes in
                            updateFocusMinutes(minutes)
                        }
                    }

                    Section("Break Length") {
                        Text("Pick how long your quick reset should be.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        presetsGrid(presets: breakPresets, selected: currentBreakMinutes) { minutes in
                            updateBreakMinutes(minutes)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Timer Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var modeSelectionBinding: Binding<TimerModeSelection> {
        Binding {
            switch viewModel.configuration.mode {
            case .continuous:
                return .continuous
            case .pomodoro:
                return .pomodoro
            }
        } set: { newValue in
            switch newValue {
            case .continuous:
                viewModel.configuration.mode = .continuous
            case .pomodoro:
                viewModel.configuration.mode = .pomodoro(
                    focusMinutes: viewModel.configuration.defaultPomodoroFocusMinutes,
                    breakMinutes: viewModel.configuration.defaultPomodoroBreakMinutes
                )
            }
        }
    }

    private var currentFocusMinutes: Int {
        switch viewModel.configuration.mode {
        case .continuous:
            return viewModel.configuration.defaultPomodoroFocusMinutes
        case .pomodoro(let focus, _):
            return focus
        }
    }

    private var currentBreakMinutes: Int {
        switch viewModel.configuration.mode {
        case .continuous:
            return viewModel.configuration.defaultPomodoroBreakMinutes
        case .pomodoro(_, let rest):
            return rest
        }
    }

    private func updateFocusMinutes(_ minutes: Int) {
        switch viewModel.configuration.mode {
        case .continuous:
            viewModel.configuration.mode = .pomodoro(
                focusMinutes: minutes,
                breakMinutes: viewModel.configuration.defaultPomodoroBreakMinutes
            )
        case .pomodoro(_, let rest):
            viewModel.configuration.mode = .pomodoro(focusMinutes: minutes, breakMinutes: rest)
        }
    }

    private func updateBreakMinutes(_ minutes: Int) {
        switch viewModel.configuration.mode {
        case .continuous:
            viewModel.configuration.mode = .pomodoro(
                focusMinutes: viewModel.configuration.defaultPomodoroFocusMinutes,
                breakMinutes: minutes
            )
        case .pomodoro(let focus, _):
            viewModel.configuration.mode = .pomodoro(focusMinutes: focus, breakMinutes: minutes)
        }
    }

    @ViewBuilder
    private func presetsGrid(
        presets: [Int],
        selected: Int,
        action: @escaping (Int) -> Void
    ) -> some View {
        let columns = [GridItem(.adaptive(minimum: 64), spacing: 12)]

        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(presets, id: \.self) { minutes in
                Button {
                    action(minutes)
                } label: {
                    Text("\(minutes)m")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    selected == minutes
                                        ? Color.accentColor.opacity(0.15)
                                        : Color(.secondarySystemBackground)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(selected == minutes ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(minutes) minute preset")
            }
        }
        .padding(.top, 4)
    }
}

private enum TimerModeSelection: String, CaseIterable, Identifiable {
    case continuous
    case pomodoro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .continuous:
            return "Continuous"
        case .pomodoro:
            return "Pomodoro"
        }
    }
}
