import Foundation

protocol SessionTimerConfigurationStoring {
    func load() -> SessionTimerConfiguration
    func save(_ configuration: SessionTimerConfiguration)
}

final class DefaultsSessionTimerConfigurationStore: SessionTimerConfigurationStoring {
    private let defaults: UserDefaults
    private let key = "sessionTimerConfiguration"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> SessionTimerConfiguration {
        guard
            let data = defaults.data(forKey: key),
            let configuration = try? JSONDecoder().decode(SessionTimerConfiguration.self, from: data)
        else {
            return .default
        }
        return configuration
    }

    func save(_ configuration: SessionTimerConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(data, forKey: key)
    }
}
