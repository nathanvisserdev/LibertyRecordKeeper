//
//  AIChatLogsView.swift
//  LibertyRecordKeeper
//
//  Created on 12/12/2025.
//

import SwiftUI

struct AIChatLogsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "text.bubble")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                
                Text("AI Chat Logs")
                    .font(.title)
                
                Text("This section will store AI conversation logs for forensic purposes")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Feature coming soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("AI Chat Logs")
        }
    }
}
