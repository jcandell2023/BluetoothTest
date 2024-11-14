//
//  PeripheralView.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/6/24.
//

import SwiftUI
import CoreBluetooth

struct PeripheralScreenView: View {
    var peripheralModel: PeripheralModel
    let peripheral: Peripheral
    @Environment(BleCentralManagerModel.self) private var bleModel
    
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
        peripheralModel = PeripheralModel(peripheral: peripheral)
    }
    
    var body: some View {
        VStack{
            Text(peripheral.value.name ?? "No Name")
            List(peripheralModel.collectedData, id: \.self) { data in
                Text(data)
            }
        }
        .onAppear {
            peripheralModel.discoverServices()
        }
        .onDisappear {
            bleModel.disconnect(peripheral)
            bleModel.startScan()
        }
    }
}
