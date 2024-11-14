//
//  HomeScreenView.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import SwiftUI

struct HomeScreenView: View {
    @Environment(BleCentralManagerModel.self) private var bleModel
    @Environment(\.navigation) private var navigation
    
    var body: some View {
        @Bindable var bleModel = bleModel
        VStack {
            if bleModel.isScanning {
                Button("Stop scanning for devices") {
                    bleModel.stopScan()
                }
            } else {
                Button("Scan for devices") {
                    bleModel.startScan()
                }
            }
            Text("Available Devices:")
            List(bleModel.peripheralsToDisplay) { device in
                HStack {
                    Text(device.name ?? "Name not found")
                    Text(device.rssiData, format: .number)
                    Spacer()
                    Button("Connect") {
                        bleModel.connect(device.peripheral)
                    }
                }
            }
        }
        .onReceive(bleModel.navigationSubject.eraseToAnyPublisher()) {
            navigation.navigate($0)
        }
        .sheet(item: $bleModel.errorString) { errorString in
            Text(errorString)
        }
    }
}
