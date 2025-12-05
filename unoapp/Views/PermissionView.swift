//
//  PermissionView.swift
//  unoapp
//
//  Created by Kawus Nouri on 05/12/2025.
//
//  Screen shown when camera permission is denied.
//  Provides clear explanation and Settings deep link.
//

import SwiftUI

/// View shown when camera permission is denied
/// Explains why camera access is needed and provides direct link to Settings
struct PermissionView: View {

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Camera icon
            Image(systemName: "camera.fill")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            // Title and explanation
            VStack(spacing: 16) {
                Text("Camera Access Required")
                    .font(.title.weight(.semibold))

                Text("Unoapp needs camera access to record football pitch footage with your ultrawide lens and Moment fisheye attachment.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Settings button
            Button(action: openSettings) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)
            }

            // Instruction text
            Text("Tap the button above, then enable Camera access for Unoapp.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Spacer()
        }
        .background(Color(.systemBackground))
    }

    /// Opens the app's Settings page directly
    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        openURL(settingsURL)
    }
}

// MARK: - Preview

#Preview {
    PermissionView()
}
