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
    @Environment(BleCentralManagerModel.self) private var bleModel
    @State private var errorString: String? = nil
    
    init(peripheral: Peripheral) {
        peripheralModel = PeripheralModel(peripheral: peripheral)
    }
    
    var body: some View {
        VStack{
            Text(peripheralModel.name ?? "No Name")
            List(peripheralModel.collectedData) { data in
                HStack(alignment: .center) {
                    Text(data.timeStamp.formatted(date: .numeric, time: .standard))
                    Text(data.value, format: .number)
                    Spacer()
                }
            }
        }
        .sheet(item: $errorString) { errorString in
            Text(errorString)
        }
        .onChange(of: peripheralModel.errorString) {
            errorString = peripheralModel.errorString
        }
        .onAppear {
            peripheralModel.discoverServices()
        }
        .onDisappear {
            peripheralModel.unsubscribeFromData()
            bleModel.disconnect(peripheralModel.peripheral)
            bleModel.startScan()
        }
    }
}
