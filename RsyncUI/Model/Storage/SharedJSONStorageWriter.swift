//
//  SharedJSONStorageWriter.swift
//  RsyncUI
//

import DecodeEncodeGeneric
import Foundation
import OSLog

actor SharedJSONStorageWriter {
    static let shared = SharedJSONStorageWriter()

    private init() {}

    func write(_ value: sending some Encodable & Sendable, to fileURL: URL) async throws {
        Logger.process.debugMessageOnly("SharedJSONStorageWriter: writing to \(fileURL)")
        let encodeddata = try EncodeGeneric().encode(value)
        try await Task.detached(priority: .utility) {
            try encodeddata.write(to: fileURL)
        }.value
    }
}
