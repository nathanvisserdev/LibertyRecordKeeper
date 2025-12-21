// tbAuthView.swift
// View for entering the time-based authentication code from Microsoft Authenticator.

import SwiftUI

struct tbAuthView: View {
    @ObservedObject var viewModel: tbAuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your authentication code")
                .font(.headline)
            TextField("6-digit code", text: $viewModel.code)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let error = viewModel.error {
                Text(error).foregroundColor(.red)
            }
            Button("Verify") {
                viewModel.verifyCode()
            }
        }
        .padding()
    }
}
