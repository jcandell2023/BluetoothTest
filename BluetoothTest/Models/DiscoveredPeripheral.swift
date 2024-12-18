//
//  DiscoveredPeripheral.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import Foundation

public struct DiscoveredPeripheral: Sendable {
    public let peripheral: Peripheral
    public let advertisementData: [String: Any]
    public var rssiData: Int
    public var isTryingToConnect = false
}

extension DiscoveredPeripheral {
    public var name: String? {
        peripheral.name
    }
}

extension DiscoveredPeripheral: Identifiable {
    public var id: UUID { peripheral.id }
}

extension DiscoveredPeripheral: Equatable {
    public static func == (lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
        lhs.peripheral == rhs.peripheral && lhs.rssiData == rhs.rssiData
    }
}
