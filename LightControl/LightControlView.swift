//
//  LightControlView.swift
//  LightControl
//
//  Created by rryu on 2023/1/13.
//

import SwiftUI

// 场景
struct LightScene: Identifiable {
    let id: Int
    let icon: String
    let titleKey: String
    var title: String { titleKey.localized }
}

enum SceneMode: Hashable {
    case staticLight
    case dynamicLight
}

enum LightScenes {
    static let staticScenes = [
        LightScene(id: 11, icon: "lightbulb.led", titleKey: "title-warm-white"),
        LightScene(id: 12, icon: "sun.max", titleKey: "title-daylight"),
        LightScene(id: 13, icon: "snowflake", titleKey: "title-cool-white"),
        LightScene(id: 14, icon: "moon", titleKey: "title-night-light"),
        LightScene(id: 6, icon: "cup.and.saucer", titleKey: "title-comfort"),
        LightScene(id: 17, icon: "paintpalette", titleKey: "title-primary-color"),
        LightScene(id: 16, icon: "leaf", titleKey: "title-relax"),
        LightScene(id: 15, icon: "person.and.background.dotted", titleKey: "title-focus"),
        LightScene(id: 18, icon: "sparkles.tv", titleKey: "title-tv-time"),
        LightScene(id: 19, icon: "tree", titleKey: "title-plant-growth"),
    ]

    static let dynamicScenes = [
        LightScene(id: 29, icon: "flame", titleKey: "title-candlelight"),
        LightScene(id: 31, icon: "water.waves", titleKey: "title-breathing-light"),
        LightScene(id: 30, icon: "rays", titleKey: "title-golden-white"),
        LightScene(id: 32, icon: "eyeglasses", titleKey: "title-steampunk"),
        LightScene(id: 5, icon: "fireplace", titleKey: "title-fireplace"),
        LightScene(id: 22, icon: "wind", titleKey: "title-autumn"),
        LightScene(id: 26, icon: "fleuron", titleKey: "title-club"),
        LightScene(id: 3, icon: "sunset", titleKey: "title-sunset"),
        LightScene(id: 2, icon: "bolt.heart", titleKey: "title-romantic"),
        LightScene(id: 4, icon: "party.popper", titleKey: "title-party"),
        LightScene(id: 8, icon: "arrow.triangle.swap", titleKey: "title-soft-colors"),
        LightScene(id: 20, icon: "camera.macro", titleKey: "title-spring"),
        LightScene(id: 21, icon: "sun.haze", titleKey: "title-summer"),
        LightScene(id: 7, icon: "tent.2", titleKey: "title-forest"),
        LightScene(id: 24, icon: "bird", titleKey: "title-jungle"),
        LightScene(id: 25, icon: "wineglass", titleKey: "title-mojito"),
        LightScene(id: 1, icon: "sailboat", titleKey: "title-ocean"),
        LightScene(id: 23, icon: "fish", titleKey: "title-deep-sea"),
        LightScene(id: 27, icon: "gift", titleKey: "title-christmas"),
        LightScene(id: 33, icon: "flame.circle", titleKey: "title-festival-of-lights"),
        LightScene(id: 28, icon: "theatermasks", titleKey: "title-halloween"),
        LightScene(id: 9, icon: "alarm", titleKey: "title-wake-up"),
        LightScene(id: 10, icon: "teddybear", titleKey: "title-bedtime"),
    ]

    static func mode(for sceneId: Int) -> SceneMode? {
        if staticScenes.contains(where: { $0.id == sceneId }) { return .staticLight }
        if dynamicScenes.contains(where: { $0.id == sceneId }) { return .dynamicLight }
        return nil
    }
}

// macOS 26+ 使用 Liquid Glass, 旧系统使用分组背景
extension View {
    // 内容分组: Liquid Glass 下不再叠加背景, 只靠间距分组
    @ViewBuilder
    func panelGroup() -> some View {
        if #available(macOS 26.0, *) {
            self.padding(.horizontal, 4)
        } else {
            self
                .padding(10)
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // 分段控件: macOS 26 只有 large 尺寸是胶囊形; flexible 让各段平分宽度, 与底部按钮对齐
    @ViewBuilder
    func panelSegmentedStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.controlSize(.large).buttonSizing(.flexible).frame(maxWidth: .infinity)
        } else {
            self
        }
    }

    // 圆形图标按钮 (返回按钮)
    @ViewBuilder
    func panelIconButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass).buttonBorderShape(.circle)
        } else {
            self.buttonStyle(.borderless)
        }
    }
}

struct SectionLabel: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let trailing = trailing {
                Text(trailing).monospacedDigit()
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }
}

struct LightControlView: View {
    let lightControl: LightControler
    @Binding var lightIp: String
    @Binding var isOn: Bool?
    let reachable: Bool
    @Binding var lightBrightness: Double
    @Binding var lightSpeed: Double
    @Binding var lightTemp: Double
    @Binding var lightScene: Int

    @State private var mode: SceneMode = .staticLight

    private var powerBinding: Binding<Bool> {
        Binding(
            get: { isOn ?? false },
            set: { on in
                isOn = on
                if on {
                    lightControl.turnOn(ip: lightIp)
                } else {
                    lightControl.turnOff(ip: lightIp)
                }
            }
        )
    }

    private var statusText: String {
        if lightIp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "status-no-ip".localized
        }
        if !reachable {
            return "status-unreachable".localized
        }
        guard let isOn = isOn else {
            return "status-connecting".localized
        }
        return isOn
            ? String(format: "status-on".localized, Int(lightBrightness.rounded()))
            : "status-off".localized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            // 亮度和色温
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(title: "brightness".localized)
                sliderRow(value: $lightBrightness, in: 10...100,
                          low: "sun.min", high: "sun.max", label: "brightness".localized) {
                    isOn = true
                    lightControl.setBrightess(ip: lightIp, brightness: lightBrightness)
                }

                SectionLabel(title: "color-temperature".localized, trailing: "\(Int((lightTemp / 100).rounded()) * 100) K")
                    .padding(.top, 4)
                sliderRow(value: $lightTemp, in: 2200...6500,
                          low: "flame", high: "snowflake", label: "color-temperature".localized) {
                    // 设置色温会退出场景; 松开时对齐到 100K
                    lightScene = 0
                    lightTemp = (lightTemp / 100).rounded() * 100
                    lightControl.setTemp(ip: lightIp, temp: lightTemp)
                }
            }
            .panelGroup()

            Picker("", selection: $mode) {
                Text("static-light".localized).tag(SceneMode.staticLight)
                Text("dynamic-light".localized).tag(SceneMode.dynamicLight)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .panelSegmentedStyle()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 10) {
                    ForEach(mode == .staticLight ? LightScenes.staticScenes : LightScenes.dynamicScenes) { scene in
                        SceneButton(scene: scene, selected: scene.id == lightScene) {
                            lightScene = scene.id
                            isOn = true
                            lightControl.setScene(ip: lightIp, scene: scene.id)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 232)

            // 只有动态场景使用速度
            if mode == .dynamicLight {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: "speed".localized)
                    sliderRow(value: $lightSpeed, in: 10...200,
                              low: "tortoise", high: "hare", label: "speed".localized) {
                        lightControl.setSpeed(ip: lightIp, speed: lightSpeed)
                    }
                }
                .panelGroup()
            }
        }
        .onAppear {
            mode = LightScenes.mode(for: lightScene) ?? .staticLight
        }
        .onChange(of: lightScene) { sceneId in
            if let sceneMode = LightScenes.mode(for: sceneId) {
                mode = sceneMode
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: isOn == true ? "lightbulb.fill" : "lightbulb")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isOn == true ? Color.white : Color.secondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(isOn == true ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)))

            VStack(alignment: .leading, spacing: 1) {
                Text("LightControl")
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("power".localized, isOn: powerBinding)
                .toggleStyle(.switch)
                .labelsHidden()
                .help("power".localized)
        }
    }

    // 滑块松开时才发送, 避免拖动时连续发包.
    // 不设 step: macOS 26 会为每个 step 画刻度, 步长太细时只是一排密集的点
    private func sliderRow(value: Binding<Double>, in range: ClosedRange<Double>,
                           low: String, high: String, label: String,
                           onCommit: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: low)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Slider(value: value, in: range, onEditingChanged: { editing in
                if !editing { onCommit() }
            })
            .accessibilityLabel(label)
            Image(systemName: high)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}

struct SceneButton: View {
    let scene: LightScene
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: scene.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(selected ? Color.white : Color.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(selected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)))
                Text(scene.title)
                    .font(.system(size: 10))
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 26, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
