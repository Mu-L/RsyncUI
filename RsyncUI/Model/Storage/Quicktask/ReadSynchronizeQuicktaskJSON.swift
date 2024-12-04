//
//  ReadSynchronizeQuicktaskJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ReadSynchronizeQuicktaskJSON {
    
    func readjsonfilequicktask() async -> SynchronizeConfiguration? {
        var filename = ""
        let path = await Homepath()
        if let path = path.fullpathmacserial {
            filename = path + "/" + "quicktask.json"
        }

        let decodeimport = await DecodeGeneric()
        do {
            if let data = try
                await decodeimport.decodestringdatafileURL(DecodeSynchronizeConfiguration.self,
                                                           fromwhere: filename)
            {
                Logger.process.info("ReadSynchronizeQuicktaskJSON - read Quicktask from permanent storage")
                return SynchronizeConfiguration(data)
            }

        } catch {
            Logger.process.info("ReadSynchronizeQuicktaskJSON some ERROR reading")
            return nil
        }
        return nil
    }

    deinit {
        Logger.process.info("ReadSynchronizeQuicktaskJSON: deinit")
    }
}

// swiftlint:enable line_length
