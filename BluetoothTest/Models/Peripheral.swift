//
//  Peripheral.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/6/24.
//

import Combine
import CoreBluetooth

public struct Peripheral {
    let value: CBPeripheral
    let discoverServices: () -> Void
    let didDiscoverServicesPublisher: () -> AnyPublisher<[CBService], Never>
    let discoverCharacteristics: (CBService) -> Void
    let didDiscoverCharacteristicsPublisher: () -> AnyPublisher<CBService, Never>
    let subscribeToCharacteristic: (CBCharacteristic) -> Void
    let characteristicValuePublisher: (CBUUID) -> AnyPublisher<Data?, Never>
}

extension Peripheral {
    public init(peripheral: CBPeripheral) {
        let delegate = peripheral.delegate as? Delegate ?? Delegate()
        peripheral.delegate = delegate
        value = peripheral
        
        discoverServices = {
            peripheral.discoverServices(nil)
        }
        
        discoverCharacteristics = { serivce in
            peripheral.discoverCharacteristics(nil, for: serivce)
        }
        
        didDiscoverServicesPublisher = {
            delegate.servicesSubject
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        didDiscoverCharacteristicsPublisher = {
            delegate.didDiscoverCharacteristicsSubject
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        subscribeToCharacteristic = { characteristic in
            peripheral.setNotifyValue(true, for: characteristic)
        }
        
        characteristicValuePublisher = { cbUuid in
            delegate.didUpdateCharacteristicSubject
                .filter {
                    cbUuid == $0.uuid
                }
                .map {
                    $0.value
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }
}

extension Peripheral {
    class Delegate: NSObject, CBPeripheralDelegate {
        var didUpdateNameSubject: PassthroughSubject<String?, Never> = .init()
        var didReadRssiSubject: PassthroughSubject<Double, Never> = .init()
        var servicesSubject: PassthroughSubject<[CBService], Never> = .init()
        var didDiscoverCharacteristicsSubject: PassthroughSubject<CBService, Never> = .init()
        var didUpdateCharacteristicSubject: PassthroughSubject<CBCharacteristic, Never> = .init()
        
        func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            didUpdateNameSubject.send(peripheral.name)
        }
        
        func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
            didReadRssiSubject.send(RSSI.doubleValue)
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
            servicesSubject.send(peripheral.services ?? [])
        }
        
        func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
            //servicesSubject.send(peripheral.services ?? [])
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
            didDiscoverCharacteristicsSubject.send(service)
        }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
            didUpdateCharacteristicSubject.send(characteristic)
        }
    }
}

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
