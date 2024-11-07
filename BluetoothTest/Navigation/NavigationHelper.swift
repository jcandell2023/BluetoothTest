//
//  NavigationHelper.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/6/24.
//

import SwiftUI

struct NavigationHelper {
    let navigate: (Route) -> Void
    let back: () -> Void
    let popToRoot: () -> Void
}

extension NavigationHelper: EnvironmentKey {
    static let defaultValue: NavigationHelper = {
       NavigationHelper(navigate: { _ in }, back: { }, popToRoot: { })
    }()
}

extension EnvironmentValues {
    var navigation: NavigationHelper {
        get { self[NavigationHelper.self] }
        set { self[NavigationHelper.self] = newValue }
    }
}
