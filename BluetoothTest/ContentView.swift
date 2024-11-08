//
//  ContentView.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/4/24.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @State private var state: String = "Unknown"
    @State private var devices: [UUID:CBPeripheral] = [:]
    var sortedDevices: [CBPeripheral] {
        Array(devices.values).filter { $0.name != nil }.sorted {
            guard let name2 = $1.name?.lowercased() else { return true }
            guard let name1 = $0.name?.lowercased() else { return false }
            
            return name1 < name2
        }
    }
    
    @Environment(\.navigation) private var navigation
    
    var body: some View {
        VStack {
            Spacer()
            Text(state)
            List(sortedDevices, id: \.identifier) { device in
                HStack {
                    VStack {
                        Text(device.identifier.uuidString)
                        if let name = device.name {
                            Text(name)
                        } else {
                            Text("Unknown name")
                        }
                    }
                    Button(device.buttonText) {
                        if device.state == .disconnected {
                            Dependencies.shared.bleManager.connectToDevice(device)
                        } else {
                            Dependencies.shared.bleManager.disconnectFromDevice(device)
                        }
                    }
                    .disabled(device.isDisbaled)
                }
            }
            Spacer()
        }
        .onReceive(Dependencies.shared.bleManager.statePublisher()){ value in
            switch value {
            case .unknown:
                state = "unknown"
            case .resetting:
                state = "resetting"
            case .poweredOn:
                state = "powered on"
                Dependencies.shared.bleManager.startScanning([BleConstants.uartServiceCBUUID])
            case .poweredOff:
                state = "powered off"
            case .unauthorized:
                state = "unauthorized"
            case .unsupported:
                state = "unsupported"
            @unknown default:
                state = "unknown"
            }
        }
        .onReceive(Dependencies.shared.bleManager.peripheralUpdatesPublisher()) { value in
            devices[value.identifier] = value
        }
        .onReceive(Dependencies.shared.bleManager.didConnectPublisher()) { peripheral in
            navigation.navigate(.deviceDetail(.init(peripheral: peripheral)))
        }
        .padding()
    }
}

extension CBPeripheral {
    var buttonText: String {
        switch self.state {
        case .connected:
            "Disconnect"
        case .disconnected:
            "Connect"
        case .connecting:
            "Connecting"
        case .disconnecting:
            "Disconnecting"
        @unknown default:
            ""
        }
    }
    
    var isDisbaled: Bool {
        switch self.state {
        case .connected, .disconnected:
            false
        case .connecting, .disconnecting:
            true
        @unknown default:
            true
        }
    }
}

#Preview {
    ContentView()
}
