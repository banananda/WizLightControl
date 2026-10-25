//
//  LightControler.swift
//  LightControl
//
//  Created by rryu on 2023/1/12.
//

import Foundation
import CryptoKit
import Socket
import Dispatch

class LightControler {
    static let signingKeyDefaultsKey = "lightSigningKey"

    private let port: Int32 = 38899
    private let queue = DispatchQueue(label: "rryu.LightControl.udp")

    // 解析签名密钥: 支持直接粘贴 32 位十六进制密钥, 或 WiZ app 导出的整个 JSON (取 udp_signing_key)
    static func parseSigningKey(_ input: String) -> SymmetricKey? {
        var hex = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("{") {
            guard let data = hex.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let key = json["udp_signing_key"] as? String else {
                return nil
            }
            hex = key.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !hex.isEmpty, hex.count % 2 == 0 else { return nil }

        var bytes = [UInt8]()
        bytes.reserveCapacity(hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return SymmetricKey(data: bytes)
    }

    // 生成 setPilot 消息. 新固件 (1.34+) 需要签名: params 中加入 sigTs,
    // 再对紧凑的 params JSON 做 HMAC-SHA256, base64 后放在顶层 hmac 字段
    static func setPilotMessage(params: [String: Any], key: SymmetricKey?, now: Date = Date()) -> String? {
        guard let key = key else {
            guard let body = try? JSONSerialization.data(withJSONObject: ["method": "setPilot", "params": params]) else {
                return nil
            }
            return String(data: body, encoding: .utf8)
        }

        var signedParams = params
        signedParams["sigTs"] = Int(now.timeIntervalSince1970)
        // 签名的字节必须与发送的 params 完全一致, 所以只序列化一次并原样拼接
        guard let paramsData = try? JSONSerialization.data(withJSONObject: signedParams, options: [.sortedKeys]),
              let paramsJson = String(data: paramsData, encoding: .utf8) else {
            return nil
        }
        let mac = HMAC<SHA256>.authenticationCode(for: paramsData, using: key)
        let hmac = Data(mac).base64EncodedString()
        return "{\"method\":\"setPilot\",\"env\":\"pro\",\"params\":\(paramsJson),\"hmac\":\"\(hmac)\"}"
    }

    // 发送信息 (在后台线程发送, 无效 IP 时直接忽略; 设置了签名密钥时自动签名)
    private func send(ip: String, params: [String: Any]) {
        let ip = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else { return }

        let keyInput = UserDefaults.standard.string(forKey: Self.signingKeyDefaultsKey) ?? ""
        let key = Self.parseSigningKey(keyInput)
        if key == nil && !keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("Invalid UDP signing key, sending unsigned")
        }
        guard let message = Self.setPilotMessage(params: params, key: key) else { return }

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
