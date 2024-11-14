//
//  ContentView.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var bleModel = BleCentralManagerModel()
    
    var body: some View {
        NavigationContainerView {
            HomeScreenView()
        }
        .environment(bleModel)
    }
}
