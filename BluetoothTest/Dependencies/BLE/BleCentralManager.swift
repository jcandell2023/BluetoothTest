//
//  BleManager.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/4/24.
//

import Combine
@preconcurrency import CoreBluetooth

// MARK: BleCentralManager
public struct BleCentralManager: Sendable {
    public var currentState: @Sendable () -> CBManagerState
    public var statePublisher: @Sendable () -> AnyPublisher<CBManagerState, Never>
    public var isScanning: @Sendable () -> Bool
    private var startScanning: @Sendable ([CBUUID]?, [String: Any]?) -> AnyPublisher<DiscoveredPeripheral, Never>
    private var connect: @Sendable (Peripheral, Int) -> AnyPublisher<Peripheral, Error>
    public var disconnect: @Sendable (Peripheral) -> Void
}

// MARK: Implementation
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
        
        startScanning = { services, options in
            delegate.didDiscoverSubject
                .handleEvents(
                    receiveSubscription: { _ in
                        centralManager.scanForPeripherals(withServices: services, options: options)
                    },
                    receiveCancel: {
                        centralManager.stopScan()
                    }
                )
                .share()
                .eraseToAnyPublisher()
        }
        
        connect = { peripheral, timeoutSeconds in
            Publishers.Merge(
                delegate.didConnectSubject
                    .filter { $0.id == peripheral.id }
                    .setFailureType(to: Error.self),
                delegate.didFailToConnectSubject
                    .filter { connectedPeripheral, _ in
                        connectedPeripheral.id == peripheral.id
                    }
                    .tryMap { _, error in
                        throw BleCentralManagerError.connectionFailed(error?.localizedDescription ?? "No error info")
                    }
            )
            .timeout(.seconds(timeoutSeconds), scheduler: DispatchQueue.main, customError: {
                BleCentralManagerError.connectionTimedOut
            })
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
}

// MARK: Public functions
extension BleCentralManager {
    public func startScanning(withServices services: [CBUUID]? = nil, options: [String: Any]? = nil) -> AnyPublisher<DiscoveredPeripheral, Never> {
        startScanning(services, options ?? [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    public func connect(to peripheral: Peripheral, timeout: Int = BleConstants.DEFAULT_TIMEOUT_SECONDS) -> AnyPublisher<Peripheral, Error> {
        connect(peripheral, timeout)
    }
}

// MARK: Mock creation
extension BleCentralManager {
    public static func mock(
        currentState: @escaping @Sendable () -> CBManagerState = { .unknown },
        statePublisher: @escaping @Sendable () -> AnyPublisher<CBManagerState, Never> = {
            PassthroughSubject<CBManagerState, Never>().eraseToAnyPublisher()
        },
        isScanning: @escaping @Sendable () -> Bool = { false },
        startScanning: @escaping @Sendable ([CBUUID]?, [String: Any]?) -> AnyPublisher<DiscoveredPeripheral, Never> = { _, _ in
            PassthroughSubject<DiscoveredPeripheral, Never>().eraseToAnyPublisher()
        },
        connect: @escaping @Sendable (Peripheral, Int) -> AnyPublisher<Peripheral, Error> = { _, _ in
            PassthroughSubject<Peripheral, Error>().eraseToAnyPublisher()
        },
        disconnect: @escaping @Sendable (Peripheral) -> Void = { _ in }
    ) -> Self {
        .init(currentState: currentState, statePublisher: statePublisher, isScanning: isScanning, startScanning: startScanning, connect: connect, disconnect: disconnect)
    }
}

// MARK: Delegate
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

// MARK: Errors
extension BleCentralManager {
    public enum BleCentralManagerError: LocalizedError, Sendable {
        case connectionFailed(String)
        case connectionTimedOut
        
        public var errorDescription: String? {
            switch self {
            case let .connectionFailed(errorInfo):
                "Connection failed: \(errorInfo)"
            case .connectionTimedOut:
                "Connection timed out"
            }
        }
    }
}
