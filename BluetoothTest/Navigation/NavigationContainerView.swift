//
//  NavigationContainerView.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/6/24.
//

import SwiftUI

struct NavigationContainerView<Content: View>: View {
    @State private var router = Router()
    @ViewBuilder let content: Content
    
    var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: Route.self) { route in
                    router.destination(for: route)
                }
        }
        .environment(\.navigation, NavigationHelper(navigate: { route in
            router.path.append(route)
        }, back: {
            router.path.removeLast()
        }, popToRoot: {
            router.path.removeAll()
        }))
    }
}
