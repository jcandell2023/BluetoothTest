//
//  MultiplePeripheralsScreenView.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import SwiftUI

struct MultiplePeripheralsScreenView: View {
    let peripherals: [Peripheral]
    
    var body: some View {
        HStack {
            ForEach(peripherals) { peripheral in
                PeripheralScreenView(peripheral: peripheral)
            }
        }
    }
}
