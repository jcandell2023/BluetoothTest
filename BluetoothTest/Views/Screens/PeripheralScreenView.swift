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
            List(peripheralModel.collectedData) { data in
                HStack(alignment: .center) {
                    Text(data.timeStamp.formatted(date: .numeric, time: .standard))
                    Text(data.value, format: .number)
                    Spacer()
                }
            }
        }
        .onAppear {
            peripheralModel.discoverServices()
        }
        .onDisappear {
            peripheralModel.unsubscribeFromData()
            bleModel.disconnect(peripheral)
            bleModel.startScan()
        }
    }
}
