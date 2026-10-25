//
//  LightSetIp.swift
//  LightControl
//
//  Created by rryu on 2023/1/13.
//

import SwiftUI

struct LightSetIp: View {
    @Binding var settingsOpen: Bool
    @Binding var lightIp: String
    @Binding var lightSigningKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        settingsOpen = false
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .panelIconButtonStyle()
                .keyboardShortcut(.cancelAction)
                .help("back".localized)

                Text("settings-title".localized)
                    .font(.headline)
            }
            .padding(.bottom, 8)

            SectionLabel(title: "section-bulb".localized)
            HStack {
                Text("ip-address".localized)
                Spacer()
                TextField("192.168.1.20", text: $lightIp)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 150)
            }
            .panelGroup()

            // UDP 签名密钥 (新固件需要, 留空则不签名)
            SectionLabel(title: "section-security".localized)
                .padding(.top, 10)
            HStack {
                Text("signing-key".localized)
                Spacer()
                SecureField("light-signing-key".localized, text: $lightSigningKey)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 150)
            }
            .panelGroup()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                signingKeyStatus.icon
                Text(signingKeyStatus.text + " " + "signing-key-hint".localized)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.caption)
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
    }

    private var signingKeyStatus: (icon: AnyView, text: String) {
        if lightSigningKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (AnyView(Image(systemName: "info.circle").foregroundStyle(.secondary)),
                    "signing-key-none".localized)
        }
        if LightControler.parseSigningKey(lightSigningKey) == nil {
            return (AnyView(Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)),
                    "signing-key-invalid".localized)
        }
        return (AnyView(Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)),
                "signing-key-valid".localized)
    }
}
