//
//  Router.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/6/24.
//

import Foundation
import SwiftUI

enum Route: Hashable {
    case deviceDetail(Peripheral)
}

@Observable
class Router {
    var path: [Route] = []
    
    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case let .deviceDetail(peripheral):
            PeripheralView(peripheral: peripheral)
        }
    }
}
