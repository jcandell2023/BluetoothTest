//
//  PeripheralModel.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import Combine
import CoreBluetooth

@Observable
class PeripheralModel {
    @ObservationIgnored
    var peripheral: Peripheral
    
    var name: String?
    
    @ObservationIgnored
    private var servicesCancellable: AnyCancellable? = nil
    @ObservationIgnored
    private var characteristicsCancellable: AnyCancellable? = nil
    @ObservationIgnored
    private var dataCancellable: AnyCancellable? = nil
    
    var services: [CBService] = []
    var characteristics: [CBCharacteristic] = []
    var collectedData: [BleData] = []
    
    var errorString: String? = nil
    
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
        name = peripheral.name
    }
    
    func discoverServices() {
        servicesCancellable = peripheral.discoverServices([BleConstants.uartServiceCBUUID])
            .receiveOnMain()
            .sink { [weak self] services in
                self?.services = services
                if let uartService = services.first(where: { $0.uuid == BleConstants.uartServiceCBUUID }) {
                    self?.discoverCharacteristics(for: uartService)
                } else {
                    self?.errorString = "Couldn't get data from this device try reconnecting"
                }
                self?.servicesCancellable = nil
            }
    }
    
    func discoverCharacteristics(for service: CBService) {
        characteristicsCancellable = peripheral.discoverCharacteristics([BleConstants.uartRxCharacteristicCBUUID], service)
            .receiveOnMain()
            .sink { [weak self] characteristics in
                self?.characteristics = characteristics
                if let uartRxCharacteristic = characteristics.first(where: { $0.uuid == BleConstants.uartRxCharacteristicCBUUID }) {
                    self?.subscribeToData(for: uartRxCharacteristic)
                } else {
                    self?.errorString = "Couldn't get data from this device try reconnecting"
                }
                self?.characteristicsCancellable = nil
            }
    }
    
    func subscribeToData(for characteristic: CBCharacteristic) {
        dataCancellable = peripheral.subscribeToCharacteristic(characteristic)
            .map { BleData(from: String(decoding: $0, as: UTF8.self)) }
            .receiveOnMain()
            .sink { [weak self] newData in
                self?.collectedData.append(newData)
            }
    }
    
    func unsubscribeFromData() {
        dataCancellable = nil
    }
}
