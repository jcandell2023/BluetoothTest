//
//  PeripheralView.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/6/24.
//

import SwiftUI
import CoreBluetooth

struct PeripheralScreenView: View {
    let peripheral: Peripheral
    @State private var services: [CBService] = []
    @State private var datas: [String] = []
    
    var body: some View {
        VStack{
            Text(peripheral.value.name ?? "No Name")
            List(services, id: \.uuid) { service in
                    Text(service.debugDescription)
            }
            List(datas, id: \.self) { data in
                Text(data)
            }
        }
        .onReceive(peripheral.didDiscoverServicesPublisher()) { newServices in
            services = newServices
            for service in services {
                peripheral.discoverCharacteristics(service)
            }
        }
        .onReceive(peripheral.didDiscoverCharacteristicsPublisher()) { service in
            if let uartRx = service.characteristics?.first(where: { $0.uuid == BleConstants.uartRxCharacteristicCBUUID}) {
                peripheral.subscribeToCharacteristic(uartRx)
            }
        }
        .onReceive(peripheral.characteristicValuePublisher(BleConstants.uartRxCharacteristicCBUUID)) { data in
            if let data {
                datas.append(String(decoding: data, as: UTF8.self))
            }
        }
        .onAppear {
            peripheral.discoverServices()
        }
    }
}
