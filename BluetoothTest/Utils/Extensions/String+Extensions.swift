//
//  String+Extensions.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import Foundation

extension String: Identifiable {
    public var id: Int { hashValue }
}
