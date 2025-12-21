// SettingsView.swift
// Main settings view with tab navigation for settings sections.

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let securitySettingsViewModel: SecuritySettingsViewModel

    var body: some View {
        VStack {
            Picker("Settings", selection: $viewModel.selectedTab) {
                ForEach(SettingsViewModel.Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            TabView(selection: $viewModel.selectedTab) {
                SecuritySettingsView(viewModel: securitySettingsViewModel)
                    .tag(SettingsViewModel.Tab.security)
                // Add more tabs/views as needed
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Settings")
    }
}
