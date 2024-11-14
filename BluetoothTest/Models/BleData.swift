//
//  BleData.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/13/24.
//

import Foundation

public struct BleData {
    let timeStamp: Date = Date.now
    let device: String
    let value: Int
}

extension BleData {
    init(from stringData: String) {
        let parts = stringData
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: ",")
        device = parts[0]
        value = Int(parts[1]) ?? 0
    }
}

extension BleData: Identifiable {
    public var id: Date { timeStamp }
}

extension BleData: Equatable { }
