//
//  BleConstants.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/8/24.
//

import CoreBluetooth

fileprivate let uartServiceUUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
fileprivate let uartTxCharacteristicUUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
fileprivate let uartRxCharacteristicUUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

public struct BleConstants {
    public static let uartServiceCBUUID = CBUUID(string: uartServiceUUID)
    public static let uartTxCharacteristicCBUUID = CBUUID(string: uartTxCharacteristicUUID)
    public static let uartRxCharacteristicCBUUID = CBUUID(string: uartRxCharacteristicUUID)
}
