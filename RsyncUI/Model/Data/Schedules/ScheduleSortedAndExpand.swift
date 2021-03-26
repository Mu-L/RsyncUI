//
//  ScheduleSortedAndExpand.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 26/03/2021.
//
// swiftlint:disable line_length cyclomatic_complexity

import Foundation

// Struct for active schedules
struct ActiveSchedules {
    var timetostart: Double?
    var hiddenID: Int
    var dateStart: Date?
    var schedule: String
    var profilename: String?

    init(_ timetostart: Double?,
         _ hiddenID: Int,
         _ dateStart: Date?,
         _ schedule: String, _ profilename: String?)
    {
        self.timetostart = timetostart
        self.hiddenID = hiddenID
        self.dateStart = dateStart
        self.schedule = schedule
        self.profilename = profilename
    }
}

final class ScheduleSortedAndExpand {
    private var structschedules: [ConfigurationSchedule]?
    private var localeprofile: String?
    var sortedexpandedeschedules: [ActiveSchedules]?

    // Calculate daily schedules
    private func daily(dateStart: Date, schedule: String, oneschedule: ConfigurationSchedule?) {
        let calendar = Calendar.current
        var days: Int?
        if dateStart.daystonow == Date().daystonow, dateStart > Date() {
            days = dateStart.daystonow
        } else {
            days = dateStart.daystonow + 1
        }
        let components = DateComponents(day: days)
        if let start: Date = calendar.date(byAdding: components, to: dateStart) {
            if start.timeIntervalSinceNow > 0 {
                if let hiddenID = oneschedule?.hiddenID {
                    let profilename = localeprofile ?? NSLocalizedString("Default profile", comment: "default profile")
                    let time = start.timeIntervalSinceNow
                    sortedexpandedeschedules?.append(ActiveSchedules(time,
                                                                     hiddenID,
                                                                     dateStart,
                                                                     schedule,
                                                                     profilename))
                }
            }
        }
    }

    // Calculate weekly schedules
    private func weekly(dateStart: Date, schedule: String, oneschedule: ConfigurationSchedule?) {
        let calendar = Calendar.current
        var weekofyear: Int?
        if dateStart.weekstonow == Date().weekstonow, dateStart > Date() {
            weekofyear = dateStart.weekstonow
        } else {
            weekofyear = dateStart.weekstonow + 1
        }
        let components = DateComponents(weekOfYear: weekofyear)
        if let start: Date = calendar.date(byAdding: components, to: dateStart) {
            if start.timeIntervalSinceNow > 0 {
                if let hiddenID = oneschedule?.hiddenID {
                    let profilename = localeprofile ?? NSLocalizedString("Default profile", comment: "default profile")
                    let time = start.timeIntervalSinceNow
                    sortedexpandedeschedules?.append(ActiveSchedules(time,
                                                                     hiddenID,
                                                                     dateStart,
                                                                     schedule,
                                                                     profilename))
                }
            }
        }
    }

    // Expanding and sorting Scheduledata
    private func sortandexpandscheduletasks() {
        guard structschedules?.count ?? 0 > 0 else { return }
        sortedexpandedeschedules = [ActiveSchedules]()
        for i in 0 ..< (structschedules?.count ?? 0) {
            let oneschedule = structschedules?[i]
            let dateStop = oneschedule?.dateStop?.en_us_date_from_string() ?? Date()
            let dateStart = oneschedule?.dateStart.en_us_date_from_string() ?? Date()
            let schedule = oneschedule?.schedule ?? Scheduletype.once.rawValue
            let seconds: Double = dateStop.timeIntervalSinceNow
            // Get all jobs which are not executed
            if seconds > 0 {
                switch schedule {
                case Scheduletype.once.rawValue:
                    if let hiddenID = oneschedule?.hiddenID {
                        let profilename = localeprofile ?? NSLocalizedString("Default profile", comment: "default profile")
                        let time = seconds
                        sortedexpandedeschedules?.append(ActiveSchedules(time,
                                                                         hiddenID,
                                                                         dateStart,
                                                                         schedule,
                                                                         profilename))
                    }
                case Scheduletype.daily.rawValue:
                    daily(dateStart: dateStart, schedule: schedule, oneschedule: oneschedule)
                case Scheduletype.weekly.rawValue:
                    weekly(dateStart: dateStart, schedule: schedule, oneschedule: oneschedule)
                default:
                    break
                }
            }
        }
        sortedexpandedeschedules = sortedexpandedeschedules?.sorted { (date1, date2) -> Bool in
            if let date1 = date1.timetostart {
                if let date2 = date2.timetostart {
                    if date1 > date2 {
                        return false
                    } else {
                        return true
                    }
                }
            }
            return false
        }
    }

    init(profile: String?,
         scheduleConfigurations: [ConfigurationSchedule]?)
    {
        localeprofile = profile
        structschedules = scheduleConfigurations
        sortandexpandscheduletasks()
    }

    deinit {
        print("deinit ScheduleSortedAndExpand")
    }
}
