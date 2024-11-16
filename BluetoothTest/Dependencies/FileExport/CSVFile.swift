//
//  CSVFile.swift
//  BluetoothTest
//
//  Created by Jeff Candell on 11/16/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVFile {
    
    var stringRepresentation: String = ""
    
    init(bleData: [BleData]) {
        stringRepresentation = "Time,Name,Value\n"
        for data in bleData {
            stringRepresentation += "\(data.timeStamp),\(data.device),\(data.value)\n"
        }
    }
}

extension CSVFile: Transferable {
    var dataRepresentation: Data {
        Data(stringRepresentation.utf8)
    }
    
    init(data: Data) {
        stringRepresentation = String(decoding: data, as: UTF8.self)
    }
    
    var suggestedFileName: String {
        return "ReinCheck-Data.csv"
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .commaSeparatedText) { file in
            file.dataRepresentation
        } importing: { data in
            CSVFile(data: data)
        }
        .suggestedFileName {
            $0.suggestedFileName
        }
    }
}

extension CSVFile: FileDocument {
    public static var readableContentTypes = [UTType.commaSeparatedText]
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.init(data: data)
        } else {
            self.init(bleData: [])
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: dataRepresentation)
    }
}
