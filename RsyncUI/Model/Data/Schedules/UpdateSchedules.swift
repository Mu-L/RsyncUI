//
//  UpdateSchedules.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 05/03/2021.
//
// swiftlint:disable trailing_comma line_length

import Foundation

enum ScheduleError: LocalizedError {
    case notselectedconfig

    var errorDescription: String? {
        switch self {
        case .notselectedconfig:
            return NSLocalizedString("Please select a configuration", comment: "ScheduleError") + "..."
        }
    }
}

final class UpdateSchedules {
    private var structschedules: [ConfigurationSchedule]?
    private var localeprofile: String?

    func add(_ hiddenID: Int?, _ schedule: EnumScheduleDatePicker, _ startdate: Date) -> Bool {
        do {
            let validdate = try validateschedule(hiddenID, schedule, startdate)
            guard validdate == true else { return false }
            addschedule(hiddenID, schedule, startdate)
            return true
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
        return false
    }

    // Function adds new Shcedules (plans). Functions writes
    // schedule plans to permanent store.
    func addschedule(_ hiddenID: Int?, _ schedule: EnumScheduleDatePicker, _ startdate: Date) {
        var stop: Date?
        var scheduletype: Scheduletype = .once
        if schedule == .once {
            stop = startdate
        } else {
            stop = "01 Jan 2100 00:00".en_us_date_from_string()
        }
        switch schedule {
        case .once:
            scheduletype = .once
        case .daily:
            scheduletype = .daily
        case .weekly:
            scheduletype = .weekly
        }
        let dict: NSDictionary = [
            DictionaryStrings.hiddenID.rawValue: hiddenID ?? -1,
            DictionaryStrings.dateStart.rawValue: startdate.en_us_string_from_date(),
            DictionaryStrings.dateStop.rawValue: stop!.en_us_string_from_date(),
            DictionaryStrings.schedule.rawValue: scheduletype.rawValue,
        ]
        let newschedule = ConfigurationSchedule(dictionary: dict, log: nil)
        structschedules?.append(newschedule)
        // Save all after adding to schedule in memory
        /*
         WriteScheduleJSON(localeprofile, structschedules)
             .savescheduleInMemoryToPersistentStore()
         */
        _ = NewWriteScheduleJSON(localeprofile, structschedules)
    }

    func validateschedule(_ hiddenID: Int?, _: EnumScheduleDatePicker, _: Date) throws -> Bool {
        if hiddenID == nil {
            throw ScheduleError.notselectedconfig
        } else {
            return true
        }
    }

    func stopschedule(uuids: Set<UUID>) {
        if let schedules = structschedules {
            var indexset = IndexSet()
            for i in 0 ..< uuids.count {
                if let index = schedules.firstIndex(where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: i)] }) {
                    indexset.insert(index)
                }
            }
            for index in indexset {
                structschedules?[index].schedule = Scheduletype.stopped.rawValue
                structschedules?[index].dateStop = Date().en_us_string_from_date()
            }
            /*
             WriteScheduleJSON(localeprofile, structschedules)
                 .savescheduleInMemoryToPersistentStore()
             */
            _ = NewWriteScheduleJSON(localeprofile, structschedules)
        }
    }

    func deleteschedules(uuids: Set<UUID>) {
        if let schedules = structschedules {
            var indexset = IndexSet()
            for i in 0 ..< uuids.count {
                if let index = schedules.firstIndex(
                    where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: i)] })
                {
                    indexset.insert(index)
                }
            }
            structschedules?.remove(atOffsets: indexset)
        }
        /*
         WriteScheduleJSON(localeprofile, structschedules)
             .savescheduleInMemoryToPersistentStore()
         */
        _ = NewWriteScheduleJSON(localeprofile, structschedules)
    }

    func deletelogs(uuids: Set<UUID>) {
        if let schedules = structschedules {
            var indexset = IndexSet()

            for i in 0 ..< schedules.count {
                for j in 0 ..< uuids.count {
                    if let index = schedules[i].logrecords?.firstIndex(
                        where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: j)] })
                    {
                        indexset.insert(index)
                    }
                }
                structschedules?[i].logrecords?.remove(atOffsets: indexset)
                indexset.removeAll()
            }
            /*
             WriteScheduleJSON(localeprofile, structschedules)
                 .savescheduleInMemoryToPersistentStore()
             */
            _ = NewWriteScheduleJSON(localeprofile, structschedules)
        }
    }

    init(profile: String?,
         scheduleConfigurations: [ConfigurationSchedule]?)
    {
        localeprofile = profile
        structschedules = scheduleConfigurations
    }

    deinit {
        // print("deinit UpdateSchedules")
    }
}

extension UpdateSchedules: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
