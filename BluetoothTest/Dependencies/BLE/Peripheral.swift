//
//  Peripheral.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/6/24.
//

import Combine
@preconcurrency import CoreBluetooth

// MARK: Peripheral
public struct Peripheral: Sendable {
    let value: CBPeripheral
    let discoverServices: @Sendable ([CBUUID]?) -> AnyPublisher<[CBService], Never>
    let discoverCharacteristics: @Sendable ([CBUUID]?, CBService) -> AnyPublisher<[CBCharacteristic], Never>
    let subscribeToCharacteristic: @Sendable (CBCharacteristic) -> AnyPublisher<Data, Never>
    let unsubscribeFromCharacteristic: @Sendable (CBCharacteristic) -> Void
}

// MARK: Implementation
extension Peripheral {
    public init(peripheral: CBPeripheral) {
        let delegate = peripheral.delegate as? Delegate ?? Delegate()
        peripheral.delegate = delegate
        value = peripheral
        
        discoverServices = { services in
            delegate.didDiscoverServicesSubject
                .handleEvents(
                    receiveSubscription: { _ in
                        peripheral.discoverServices(services)
                    }
                )
                .share()
                .eraseToAnyPublisher()
        }
        
        discoverCharacteristics = { characteristics, service in
            delegate.didDiscoverCharacteristicsSubject
                .filter {
                    $0.uuid == service.uuid
                }
                .map { $0.characteristics ?? [] }
                .handleEvents(
                    receiveSubscription: { _ in
                        peripheral.discoverCharacteristics(characteristics, for: service)
                    }
                )
                .share()
                .eraseToAnyPublisher()
        }
        
        subscribeToCharacteristic = { characteristic in
            delegate.didUpdateCharacteristicSubject
                .filter {
                    $0.uuid == characteristic.uuid
                }
                .compactMap { $0.value }
                .handleEvents(
                    receiveSubscription: { _ in
                        peripheral.setNotifyValue(true, for: characteristic)
                    },
                    receiveCancel: {
                        peripheral.setNotifyValue(false, for: characteristic)
                    }
                )
                .share()
                .eraseToAnyPublisher()
        }
        
        unsubscribeFromCharacteristic = { characteristic in
            peripheral.setNotifyValue(false, for: characteristic)
        }
    }
    
    var name: String? {
        value.name
    }
    
    var state: CBPeripheralState {
        value.state
    }
}

// MARK: Delegate
extension Peripheral {
    class Delegate: NSObject, CBPeripheralDelegate {
        var didUpdateNameSubject: PassthroughSubject<String?, Never> = .init()
        var didReadRssiSubject: PassthroughSubject<Double, Never> = .init()
        var didDiscoverServicesSubject: PassthroughSubject<[CBService], Never> = .init()
        var didDiscoverCharacteristicsSubject: PassthroughSubject<CBService, Never> = .init()
        var didUpdateCharacteristicSubject: PassthroughSubject<CBCharacteristic, Never> = .init()
        
        func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            didUpdateNameSubject.send(peripheral.name)
        }
        
        func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
            didReadRssiSubject.send(RSSI.doubleValue)
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
            didDiscoverServicesSubject.send(peripheral.services ?? [])
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
            didDiscoverCharacteristicsSubject.send(service)
        }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
            didUpdateCharacteristicSubject.send(characteristic)
        }
    }
}

// MARK: Errors
extension Peripheral {
    public enum PeripheralError: LocalizedError, Sendable {
        case servicesNotFound
        case characteristicNotFound
        
        public var errorDescription: String? {
            switch self {
            case .servicesNotFound:
                "No services found for those identifiers"
            case .characteristicNotFound:
                "No characteristics found for those identifiers"
            }
        }
    }
}

// MARK: Protocols
extension Peripheral: Identifiable {
    public var id: UUID { value.identifier }
}

extension Peripheral: Hashable, Equatable {
    public static func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
