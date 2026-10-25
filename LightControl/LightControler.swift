//
//  LightControler.swift
//  LightControl
//
//  Created by rryu on 2023/1/12.
//

import Foundation
import Socket
import Dispatch

class LightControler {
    private let port: Int32 = 38899
    private let queue = DispatchQueue(label: "rryu.LightControl.udp")

    // 发送信息 (在后台线程发送, 无效 IP 时直接忽略)
    private func send(ip: String, params: [String: Any]) {
        let ip = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty,
              let body = try? JSONSerialization.data(withJSONObject: ["method": "setPilot", "params": params]),
              let message = String(data: body, encoding: .utf8) else {
            return
        }

        queue.async { [port] in
            guard let addr = Socket.createAddress(for: ip, on: port) else {
                print("Invalid light address: \(ip)")
                return
            }
            do {
                let s = try Socket.create(family: .inet, type: .datagram, proto: .udp)
                defer { s.close() }
                try s.write(from: message, to: addr)
            } catch let error {
                print(error)
            }
        }
    }

    // 开灯
    func turnOn(ip: String) {
        send(ip: ip, params: ["state": true])
    }

    // 关灯
    func turnOff(ip: String) {
        send(ip: ip, params: ["state": false])
    }

    // 改变场景
    func setScene(ip: String, scene: Int) {
        send(ip: ip, params: ["sceneID": scene, "state": true])
    }

    // 调节色温
    func setTemp(ip: String, temp: Double = 4400) {
        send(ip: ip, params: ["temp": Int(temp.rounded())])
    }

    // 调节亮度
    func setBrightess(ip: String, brightness: Double = 100) {
        send(ip: ip, params: ["dimming": Int(brightness.rounded()), "state": true])
    }

    // 调节速度
    func setSpeed(ip: String, speed: Double = 100) {
        send(ip: ip, params: ["speed": Int(speed.rounded())])
    }

}
