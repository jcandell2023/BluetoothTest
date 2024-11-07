//
//  Dependencies.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/4/24.
//

import Foundation

public class Dependencies {
    static var shared = Dependencies()
    
    public var bleManager: BleManager
    
    public init(bleManager: BleManager = .init()) {
        self.bleManager = bleManager
    }
}
