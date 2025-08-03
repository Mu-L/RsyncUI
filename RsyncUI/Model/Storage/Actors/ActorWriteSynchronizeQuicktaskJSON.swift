//
//  ActorWriteSynchronizeQuicktaskJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorWriteSynchronizeQuicktaskJSON {
    @concurrent
    private nonisolated func writeJSONToPersistentStore(jsonData: Data?) async {
        let path = await Homepath()

        Logger.process.info("ActorWriteSynchronizeQuicktaskJSON: writeJSONToPersistentStore() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

        if let fullpathmacserial = path.fullpathmacserial {
            var configurationfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            configurationfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().filenamequicktaskjson)
            if let jsonData, let configurationfileURL {
                do {
                    try jsonData.write(to: configurationfileURL)
                    Logger.process.info("ActorWriteSynchronizeQuicktaskJSON: write Quicktask to permanent storage")
                } catch let e {
                    Logger.process.error("ActorWriteSynchronizeQuicktaskJSON: some ERROR write Quicktask to permanent storage")
                    let error = e
                    await path.propogateerror(error: error)
                }
            }
        }
    }

    @concurrent
    private nonisolated func encodeJSONData(_ configuration: SynchronizeConfiguration) async {
        let encodejsondata = await EncodeGeneric()
        do {
            if let encodeddata = try await encodejsondata.encodedata(data: configuration) {
                await writeJSONToPersistentStore(jsonData: encodeddata)
            }
        } catch {
            Logger.process.error("ActorWriteSynchronizeQuicktaskJSON some ERROR writing")
            return
        }
    }

    @discardableResult
    init(_ configurations: SynchronizeConfiguration) async {
        await encodeJSONData(configurations)
    }

    deinit {
        Logger.process.info("ActorWriteSynchronizeQuicktaskJSON DEINIT")
    }
}

// swiftlint:enable line_length
