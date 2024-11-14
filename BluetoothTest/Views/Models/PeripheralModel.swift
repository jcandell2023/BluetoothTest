//
//  PeripheralModel.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import Combine
import CoreBluetooth
import Foundation

@Observable
class PeripheralModel {
    @ObservationIgnored
    private var peripheral: Peripheral
    
    @ObservationIgnored
    private var servicesCancellable: AnyCancellable? = nil
    @ObservationIgnored
    private var characteristicsCancellable: AnyCancellable? = nil
    @ObservationIgnored
    private var dataCancellable: AnyCancellable? = nil
    
    var services: [CBService] = []
    var characteristics: [CBCharacteristic] = []
    var collectedData: [String] = []
    
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
    }
    
    func discoverServices() {
        servicesCancellable = peripheral.discoverServices([BleConstants.uartServiceCBUUID])
            .receiveOnMain()
            .sink { [weak self] services in
                self?.services = services
                if let uartService = services.first(where: { $0.uuid == BleConstants.uartServiceCBUUID }) {
                    self?.discoverCharacteristics(for: uartService)
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
                }
                self?.characteristicsCancellable = nil
            }
    }
    
    func subscribeToData(for characteristic: CBCharacteristic) {
        dataCancellable = peripheral.subscribeToCharacteristic(characteristic)
            .map { String(decoding: $0, as: UTF8.self) }
            .scan([], { list, nextData in
                list + [nextData]
            })
            .sink { dataArray in
                self.collectedData = dataArray
            }
    }
}
