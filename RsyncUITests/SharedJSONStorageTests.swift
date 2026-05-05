//
//  SharedJSONStorageTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@Suite(.tags(.storage))
struct SharedJSONStorageTests {
    @Test("Shared JSON storage round-trips a single value")
    func roundTripSingleValue() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("single.json")
        let sample = SampleRecord(id: 7, name: "single")

        try await SharedJSONStorageWriter.shared.write(sample, to: fileURL)

        let decoded = try await SharedJSONStorageReader.shared.decode(SampleRecord.self, from: fileURL)

        #expect(decoded == sample)
    }

    @Test("Shared JSON storage round-trips arrays")
    func roundTripArray() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("array.json")
        let sample = [
            SampleRecord(id: 1, name: "first"),
            SampleRecord(id: 2, name: "second")
        ]

        try await SharedJSONStorageWriter.shared.write(sample, to: fileURL)

        let decoded = try await SharedJSONStorageReader.shared.decodeArray(SampleRecord.self, from: fileURL)

        #expect(decoded == sample)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return directoryURL
    }
}

private struct SampleRecord: Codable, Equatable, Sendable {
    let id: Int
    let name: String
}
