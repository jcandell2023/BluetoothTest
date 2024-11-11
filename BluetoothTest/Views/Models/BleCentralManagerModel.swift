//
//  BleCentralManagerModel.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/10/24.
//

import Foundation
import Combine
import CoreBluetooth

@Observable
class BleCentralManagerModel {
    @ObservationIgnored
    private var manager: BleCentralManager
    
    @ObservationIgnored
    private var scanCancellable: AnyCancellable? = nil
    @ObservationIgnored
    private var stateUpdatesCancellable: AnyCancellable? = nil
    @ObservationIgnored
    private var connectionCancellable: AnyCancellable? = nil
    
    @ObservationIgnored
    var navigationSubject = PassthroughSubject<Route, Never>()
    
    @ObservationIgnored
    private var connectedPeripherals: [Peripheral] = []
    
    var errorString: String? = nil
    var isScanning: Bool = false
    
    var discoveredDevices: [UUID: DiscoveredPeripheral] = [:]
    var devicesToDisplay: [DiscoveredPeripheral] {
        Array(discoveredDevices.values).filter { $0.name != nil }.sorted {
            guard let name2 = $1.name?.lowercased() else { return true }
            guard let name1 = $0.name?.lowercased() else { return false }
            return name1 < name2
        }
    }
    
    init(manager: BleCentralManager = .init()) {
        self.manager = manager
        monitorBluetoothState()
    }
    
    func monitorBluetoothState() {
        stateUpdatesCancellable = manager.statePublisher()
            .receiveOnMain()
            .sink { [weak self] newState in
                switch newState {
                case .poweredOn:
                    self?.errorString = nil
                    self?.startScan()
                case .poweredOff:
                    self?.errorString = "Please turn on bluetooth"
                case .unauthorized:
                    self?.errorString = "Please give the app acess to bluetooth to connect"
                case .resetting:
                    self?.errorString = "An error occured, please try again"
                case .unsupported:
                    self?.errorString = "Your device isn't compatible with the app"
                case .unknown:
                    self?.errorString = "Unknown error"
                @unknown default:
                    self?.errorString = "Unknown error"
                }
            }
    }
    
    func startScan() {
        scanCancellable = manager.startScanning([BleConstants.uartServiceCBUUID])
            .scan([:], { dict, newDevice -> [UUID: DiscoveredPeripheral] in
                var newDict = dict
                newDict[newDevice.id] = newDevice
                return newDict
            })
            .receiveOnMain()
            .sink { [weak self] discoveredDevices in
                self?.discoveredDevices = discoveredDevices
            }
        isScanning = manager.isScanning()
    }
    
    func stopScan() {
        scanCancellable = nil
        isScanning = manager.isScanning()
    }
    
    func connect(_ peripheral: Peripheral) {
        connectionCancellable = manager.connect(peripheral)
            .timeout(.seconds(10), scheduler: DispatchQueue.main, customError: nil)
            .map { Result.success($0) }
            .catch { Just(Result.failure($0)) }
            .receiveOnMain()
            .sink (
                receiveCompletion: { [weak self] _ in
                    self?.errorString = "Timed out trying to connect"
                },
                receiveValue: { [weak self] result in
                    switch result {
                    case let .success(connectedPeripheral):
                        self?.navigationSubject.send(.deviceDetail(connectedPeripheral))
                        self?.stopScan()
//                        self?.connectedPeripherals.append(connectedPeripheral)
//                        if let connectedPeripherals = self?.connectedPeripherals,
//                           connectedPeripherals.count > 1 {
//                            self?.navigationSubject.send(.multipleView(connectedPeripherals))
//                            self?.stopScan()
//                        }
                    case let .failure(error):
                        self?.errorString = error.localizedDescription
                    }
                    self?.connectionCancellable = nil
                }
            )
    }
}
