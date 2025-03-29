//
//  ActorReadSchedule.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadSchedule {
    nonisolated func readjsonfilecalendar(_ validprofiles: [String]) async -> [SchedulesConfigurations]? {
        var filename = ""
        let path = await Homepath()

        Logger.process.info("ActorReadSchedule: readjsonfilecalendar() MAIN THREAD \(Thread.isMain)")

        if let path = path.fullpathmacserial {
            filename = path + "/" + "calendar.json"
        }

        let decodeimport = await DecodeGeneric()
        do {
            if let data = try
                await decodeimport.decodearraydatafileURL(DecodeSchedules.self,
                                                          fromwhere: filename) {
                Logger.process.info("ActorReadSchedule - read Calendar from permanent storage")

                return data.compactMap { element in
                    let item = SchedulesConfigurations(element)
                    return validprofiles.contains(item.profile ?? "") ? item : nil
                }
            }

        } catch let e {
            Logger.process.info("ActorReadSchedule: some ERROR reading")
            let error = e
            await path.propogateerror(error: error)
        }

        return nil
    }

    deinit {
        Logger.process.info("ActorReadSchedule: deinit")
    }
}

// swiftlint:enable line_length
