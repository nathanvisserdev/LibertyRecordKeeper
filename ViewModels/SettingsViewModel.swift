// SettingsViewModel.swift
// ViewModel for application settings, including tab selection.

import Foundation

class SettingsViewModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case security = "Security Settings"
        // Add more tabs as needed
        var id: String { rawValue }
    }

    @Published var selectedTab: Tab = .security
}
