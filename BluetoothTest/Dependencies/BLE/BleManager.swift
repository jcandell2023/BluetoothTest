//
//  BleManager.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/4/24.
//

import Foundation
import CoreBluetooth
import Combine

public struct BleManager: Sendable {
    public var statePublisher: @Sendable () -> AnyPublisher<CBManagerState, Never>
    public var currentState: @Sendable () -> CBManagerState
    public var peripheralUpdatesPublisher: @Sendable () -> AnyPublisher<CBPeripheral, Never>
    public var didConnectPublisher: @Sendable () -> AnyPublisher<CBPeripheral, Never>
    public var startScanning: @Sendable () -> Void
    public var connectToDevice: @Sendable (CBPeripheral) -> Void
    public var disconnectFromDevice: @Sendable (CBPeripheral) -> Void
}

extension BleManager {
    public init() {
        let delegate = Delegate()
        let centralManager = CBCentralManager(delegate: delegate, queue: DispatchQueue(label: "BleManager", qos: .background))
        
        statePublisher = {
            delegate.didUpdateStateSubject
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        currentState = {
            centralManager.state
        }
        
        peripheralUpdatesPublisher = {
            Publishers.Merge5(
                delegate.didDiscoverSubject,
                delegate.didConnectSubject,
                delegate.connectionEventDidOccurSubject,
                delegate.didFailToConnectSubject,
                delegate.didDisconnectPeripheralSubject
            )
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        }
        
        didConnectPublisher = {
            delegate.didConnectSubject
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        startScanning = {
            centralManager.scanForPeripherals(withServices: [])
        }
        
        connectToDevice = { peripheral in
            centralManager.connect(peripheral)
        }
        
        disconnectFromDevice = { peripheral in
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

extension BleManager {
    class Delegate: NSObject, CBCentralManagerDelegate {
        var didUpdateStateSubject: PassthroughSubject<CBManagerState, Never> = .init()
        var didDiscoverSubject: PassthroughSubject<CBPeripheral, Never> = .init()
        var didConnectSubject: PassthroughSubject<CBPeripheral, Never> = .init()
        var connectionEventDidOccurSubject: PassthroughSubject<CBPeripheral, Never> = .init()
        var didFailToConnectSubject: PassthroughSubject<CBPeripheral, Never> = .init()
        var didDisconnectPeripheralSubject: PassthroughSubject<CBPeripheral, Never> = .init()
        
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            didUpdateStateSubject.send(central.state)
        }
        
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            didDiscoverSubject.send(peripheral)
        }
        
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            didConnectSubject.send(peripheral)
        }
        
        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
            didFailToConnectSubject.send(peripheral)
        }
        
        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
            didDisconnectPeripheralSubject.send(peripheral)
        }
        
        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
            didDisconnectPeripheralSubject.send(peripheral)
        }
        
        func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
            connectionEventDidOccurSubject.send(peripheral)
        }
    }
}
