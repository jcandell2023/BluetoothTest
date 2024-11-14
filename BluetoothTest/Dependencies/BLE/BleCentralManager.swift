//
//  BleManager.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/4/24.
//

import Foundation
import CoreBluetooth
import Combine

public struct BleCentralManager: Sendable {
    public var currentState: @Sendable () -> CBManagerState
    public var statePublisher: @Sendable () -> AnyPublisher<CBManagerState, Never>
    public var isScanning: @Sendable () -> Bool
    public var startScanning: @Sendable ([CBUUID]?) -> AnyPublisher<DiscoveredPeripheral, Never>
    public var connect: @Sendable (Peripheral) -> AnyPublisher<Peripheral, Error>
    public var disconnect: @Sendable (Peripheral) -> Void
}

extension BleCentralManager {
    public init() {
        let delegate = Delegate()
        let centralManager = CBCentralManager(delegate: delegate, queue: DispatchQueue(label: "BleManager", target: .global()))
        
        statePublisher = {
            delegate.didUpdateStateSubject
                .eraseToAnyPublisher()
        }
        
        currentState = {
            centralManager.state
        }
        
        isScanning = {
            centralManager.isScanning
        }
        
        startScanning = { services in
            delegate.didDiscoverSubject
                .handleEvents(
                    receiveSubscription: { _ in
                        centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                    },
                    receiveCancel: {
                        centralManager.stopScan()
                    }
                )
                .share()
                .eraseToAnyPublisher()
        }
        
        connect = { peripheral in
            Publishers.Merge(
                delegate.didConnectSubject
                    .filter { $0.id == peripheral.id }
                    .setFailureType(to: Error.self),
                delegate.didFailToConnectSubject
                    .filter { connectedPeripheral, _ in
                        connectedPeripheral.id == peripheral.id
                    }
                    .tryMap { _, error in
                        throw error ?? BleCentralManagerError.unknownError
                    }
            )
            .handleEvents(
                receiveSubscription: { _ in
                    centralManager.connect(peripheral.value)
                },
                receiveCompletion: { _ in
                    centralManager.cancelPeripheralConnection(peripheral.value)
                }
            )
            .share()
            .eraseToAnyPublisher()
        }
        
        disconnect = { peripheral in
            centralManager.cancelPeripheralConnection(peripheral.value)
        }
    }
    
    public static func mock(
        currentState: @escaping @Sendable () -> CBManagerState = { .unknown },
        statePublisher: @escaping @Sendable () -> AnyPublisher<CBManagerState, Never> = {
            PassthroughSubject<CBManagerState, Never>().eraseToAnyPublisher()
        },
        isScanning: @escaping @Sendable () -> Bool = { false },
        startScanning: @escaping @Sendable ([CBUUID]?) -> AnyPublisher<DiscoveredPeripheral, Never> = { _ in
            PassthroughSubject<DiscoveredPeripheral, Never>().eraseToAnyPublisher()
        },
        connect: @escaping @Sendable (Peripheral) -> AnyPublisher<Peripheral, Error> = { _ in
            PassthroughSubject<Peripheral, Error>().eraseToAnyPublisher()
        },
        disconnect: @escaping @Sendable (Peripheral) -> Void = { _ in }
    ) -> Self {
        .init(currentState: currentState, statePublisher: statePublisher, isScanning: isScanning, startScanning: startScanning, connect: connect, disconnect: disconnect)
    }
}

extension BleCentralManager {
    class Delegate: NSObject, CBCentralManagerDelegate {
        var didUpdateStateSubject: PassthroughSubject<CBManagerState, Never> = .init()
        var didDiscoverSubject: PassthroughSubject<DiscoveredPeripheral, Never> = .init()
        var didConnectSubject: PassthroughSubject<Peripheral, Never> = .init()
        var didFailToConnectSubject: PassthroughSubject<(Peripheral, Error?), Never> = .init()
        var didDisconnectPeripheralSubject: PassthroughSubject<(Peripheral, Error?), Never> = .init()
        
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            didUpdateStateSubject.send(central.state)
        }
        
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            didDiscoverSubject.send(
                .init(
                    peripheral: .init(peripheral: peripheral),
                    advertisementData: advertisementData,
                    rssiData: RSSI.intValue
                )
            )
        }
        
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            didConnectSubject.send(.init(peripheral: peripheral))
        }
        
        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
            didFailToConnectSubject.send((.init(peripheral: peripheral), error))
        }
        
        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
            didDisconnectPeripheralSubject.send((.init(peripheral: peripheral), error))
        }
    }
}

extension BleCentralManager {
    enum BleCentralManagerError: Error, Sendable {
        case unknownError
    }
}
