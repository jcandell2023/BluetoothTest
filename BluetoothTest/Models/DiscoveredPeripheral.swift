//
//  DiscoveredPeripheral.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import CoreBluetooth
import Foundation

public struct DiscoveredPeripheral {
    public let peripheral: Peripheral
    public let advertisementData: [String: Any]
    public var rssiData: Int
}

extension DiscoveredPeripheral {
    public var name: String? {
        peripheral.value.name
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
