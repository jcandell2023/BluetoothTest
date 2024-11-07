//
//  PeripheralView.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/6/24.
//

import SwiftUI

struct PeripheralView: View {
    let peripheral: Peripheral
    
    var body: some View {
        VStack{
            
        }
        Text(peripheral.value.name ?? "No Name")
    }
}
