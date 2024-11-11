//
//  Publisher+Extensions.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import Combine
import Foundation

extension Publisher {
    func receiveOnMain() -> AnyPublisher<Output, Failure> {
        self
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
