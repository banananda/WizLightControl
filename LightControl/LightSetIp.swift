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
        VStack {
            HStack {
                TextField("light-setip".localized,text: $lightIp)
                    .padding()
                    .frame(width:300, height: 40.0)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .background {
                        RoundedRectangle(cornerRadius: 5.0)
                            .fill(.tertiary)
                    }

            }
            .padding()

            // UDP 签名密钥 (新固件需要, 留空则不签名)
            VStack(spacing: 6) {
                SecureField("light-signing-key".localized, text: $lightSigningKey)
                    .padding()
                    .frame(width:300, height: 40.0)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .background {
                        RoundedRectangle(cornerRadius: 5.0)
                            .fill(.tertiary)
                    }

                Text(signingKeyStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 300)
                    .multilineTextAlignment(.center)
            }

        }
        .padding()
        .frame(width: 400)

    }

    private var signingKeyStatus: String {
        if lightSigningKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "signing-key-none".localized
        }
        return LightControler.parseSigningKey(lightSigningKey) == nil
            ? "signing-key-invalid".localized
            : "signing-key-valid".localized
    }
}
