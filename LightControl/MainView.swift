//
//  MainView.swift
//  LightControl
//
//  Created by rryu on 2023/1/13.
//

import SwiftUI

struct MainView: View {
    @State private var settingsOpen: Bool  = false
    @AppStorage("lightIp") var lightIp: String = ""
    @AppStorage(LightControler.signingKeyDefaultsKey) var lightSigningKey: String = ""
    @AppStorage("lightBrightness") var lightBrightness: Double = 50
    @AppStorage("lightSpeed") var lightSpeed: Double = 50
    @AppStorage("lightTemp") var lightTemp: Double = 4400
    @AppStorage("lightScene") var lightScene: Int = 0
    @State private var isOn: Bool?
    @State private var reachable = true
    @State var lightControl = LightControler()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            if (settingsOpen) {
                LightSetIp(settingsOpen: $settingsOpen, lightIp: $lightIp, lightSigningKey: $lightSigningKey)
            } else {
                LightControlView(lightControl: lightControl, lightIp: $lightIp, isOn: $isOn, reachable: reachable,
                                 lightBrightness: $lightBrightness, lightSpeed: $lightSpeed, lightTemp: $lightTemp,
                                 lightScene: $lightScene)
            }

            footer
        }
        .padding(14)
        .frame(width: 300)
        .onAppear(perform: refresh)
        // 每次打开菜单栏窗口时刷新灯泡状态
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refresh()
        }
        .onChange(of: settingsOpen) { open in
            if !open { refresh() }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if #available(macOS 26.0, *) {
            HStack(spacing: 8) {
                if !settingsOpen {
                    settingsButton
                        .frame(maxWidth: .infinity)
                }
                quitButton
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        } else {
            VStack(spacing: 8) {
                Divider()
                HStack {
                    if !settingsOpen {
                        settingsButton
                    }
                    Spacer()
                    quitButton
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
            }
        }
    }

    private var settingsButton: some View {
        Button {
            withAnimation {
                settingsOpen = true
            }
        } label: {
            Text("settings".localized)
                .frame(maxWidth: .infinity)
        }
        .keyboardShortcut(",")
    }

    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("help-quit".localized)
                .frame(maxWidth: .infinity)
        }
        .keyboardShortcut("q")
    }

    // 读取灯泡当前状态, 同步开关, 亮度, 色温和场景
    private func refresh() {
        lightControl.fetchState(ip: lightIp) { state in
            reachable = state != nil
            guard let state = state else { return }
            isOn = state.isOn
            if let dimming = state.dimming {
                lightBrightness = Double(dimming)
            }
            if let temp = state.temp, temp > 0 {
                lightTemp = Double(temp)
            }
            lightScene = state.sceneId ?? 0
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
