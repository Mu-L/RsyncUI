//
//  ObservableSchedules.swift
//  Calendar
//
//  Created by Thomas Evensen on 27/03/2025.
//

import Foundation
import Observation
import OSLog
import SwiftUI

@Observable @MainActor
final class ObservableSchedules {
    let globaltimer = GlobalTimer.shared

    @ObservationIgnored var lastdateinpresentmont: Date?

    // var scheduledata: [SchedulesConfigurations]?
    // First schedule to execute
    // var firstscheduledate: SchedulesConfigurations?
    // Trigger execution
    // var scheduledprofile: String = ""

    private func computefuturedates(profile: String?, schedule: String, dateRun: Date) {
        var dateComponents = DateComponents()

        // Last date in month is NOT set when loading data at startup
        if lastdateinpresentmont == nil {
            lastdateinpresentmont = Date.now.endOfMonth
        }

        switch schedule {
        case ScheduleType.daily.rawValue:
            dateComponents.day = 1
        /*
         case ScheduleType.weekly.rawValue:
             dateComponents.day = 7
          */
        case ScheduleType.once.rawValue:
            // Handle once as a special case, only daily and weekly needs repeat
            if let lastdateinpresentmont {
                if dateRun.monthInt == lastdateinpresentmont.monthInt {
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: ScheduleType.once.rawValue)
                }
            }
            return
        default:
            return
        }
        // This date is incrementet by schedule
        var computedDateRun: Date = dateRun

        if let lastdateinpresentmont {
            let timeInterval: TimeInterval = lastdateinpresentmont.timeIntervalSince(computedDateRun)

            guard timeInterval > 0 else { return }

            var index = 0

            switch dateComponents.day ?? 0 {
            case 1:
                index = Int(timeInterval / (60 * 60 * 24))
                // Must add the first registered date as well
                if dateRun.monthInt == lastdateinpresentmont.monthInt {
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: ScheduleType.daily.rawValue)
                }
            /*
             case 7:
                 index = Int(timeInterval / (60 * 60 * 24 * 7))
                 // Must add the first registered date as well
                 if dateRun.monthInt == lastdateinpresentmont.monthInt {
                     appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: "")
                 }
              */
            default:
                break
            }
            // Loops only for daily and weekly
            for _ in 0 ..< index {
                if let futureDate = Calendar.current.date(byAdding: dateComponents, to: computedDateRun) {
                    let futureDateString = futureDate.en_string_from_date()
                    // Set computedDateRun to next futureDate, adding dateComponents will compute
                    // the next futureDate again.
                    computedDateRun = futureDate
                    // Only add futuredates in month presented
                    if futureDate.monthInt == lastdateinpresentmont.monthInt {
                        appendfutureschedule(profile: profile, dateRun: futureDateString, schedule: ScheduleType.daily.rawValue)
                    }

                } else {
                    Logger.process.warning("ObservableFutureSchedules: Failed to calculate future dates")
                }
            }
            let count = globaltimer.allSchedules.count
            Logger.process.info("ObservableFutureSchedules: private computefuturedates(): (\(count))")
        }
    }

    // CAUTION: check for DEMO mode or not
    func appendfutureschedule(profile: String?, dateRun: String, schedule: String) {
        guard dateRun.en_date_from_string() >= Date.now else { return }
        let futureschedule = SchedulesConfigurations(profile: profile,
                                                     dateAdded: Date.now.en_string_from_date(),
                                                     dateRun: dateRun,
                                                     schedule: schedule)
        addtaskandcallback(futureschedule)
    }

    // Recompute the calendardata to only show active schedules in row.
    func recomputeschedules() {
        Logger.process.info("ObservableFutureSchedules: recomputeschedules()")
        let recomputedschedules = globaltimer.allSchedules.filter { item in
            if let dateRunString = item.scheduledata?.dateRun {
                return dateRunString.en_date_from_string() > Date.now
            }
            return false
        }

        guard recomputedschedules.count > 0 else {
            globaltimer.invalidateAllSchedulesAndTimer()
            globaltimer.firstscheduledate = nil
            Logger.process.info("ObservableFutureSchedules: recomputeschedules() no schdeules")

            return
        }

        Logger.process.info("ObservableFutureSchedules: recomputeschedules() number of schedules: \(recomputedschedules.count, privacy: .public)")

        for i in 0 ..< recomputedschedules.count {
            if let schedule = recomputedschedules[i].scheduledata?.schedule,
               let dateRun = recomputedschedules[i].scheduledata?.dateRun?.validate_en_date_from_string()
            {
                computefuturedates(profile: recomputedschedules[i].scheduledata?.profile, schedule: schedule, dateRun: dateRun)
            }
        }

        globaltimer.setfirsscheduledate()
    }

    private func addtaskandcallback(_ schedule: SchedulesConfigurations) {
        // The Callback for Schedule
        let callback: () -> Void = { [weak self] in
            guard let self else { return }
            globaltimer.scheduleNextTimer()
            // Setting profile name will trigger execution
            globaltimer.scheduledprofile = schedule.profile ?? "Default"
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for \(schedule.profile ?? "Default")"])
            }
        }
        // Then add new schedule
        if let schedultime = schedule.dateRun?.en_date_from_string() {
            globaltimer.addSchedule(time: schedultime,
                                    tolerance: 10,
                                    callback: callback,
                                    scheduledata: schedule)
        }
    }

    // Apply Scheduledata read from file, used by SidebarMainView
    func appendschdeuldatafromfile(_ schedules: [SchedulesConfigurations]) {
        for i in 0 ..< schedules.count {
            if let schedule = schedules[i].schedule,
               let dateRun = schedules[i].dateRun?.validate_en_date_from_string()
            {
                computefuturedates(profile: schedules[i].profile, schedule: schedule, dateRun: dateRun)
            }
        }

        globaltimer.setfirsscheduledate()
    }

    // Verify new planned schedule
    func verifynextschedule(plannednextschedule: String) -> Bool {
        let dates = globaltimer.allSchedules.sorted { s1, s2 in
            if let id1 = s1.scheduledata?.dateRun?.en_date_from_string(),
               let id2 = s2.scheduledata?.dateRun?.en_date_from_string()
            {
                return id1 < id2
            }
            return false
        }

        if dates.count > 0 {
            // Pick the first schedule
            if let firstschedulestring = dates.first?.scheduledata?.dateRun {
                let firstscheduledate = firstschedulestring.en_date_from_string()
                let plannedDate = plannednextschedule.en_date_from_string()

                // Case 1: plannednextschedule is at least 10 minutes AFTER firstscheduledate
                if plannedDate >= firstscheduledate.addingTimeInterval(10 * 60) {
                    return true
                }

                // Case 2: plannednextschedule is between (firstscheduledate - 10 min) and > now
                if plannedDate <= firstscheduledate.addingTimeInterval(-10 * 60),
                   plannedDate > Date.now
                {
                    return true
                }

                return false
            }
        }

        // No schedules added yet
        return plannednextschedule.en_date_from_string() > Date.now
    }

    // Delete by IndexSet
    func delete(_ uuids: Set<UUID>) {
        globaltimer.allSchedules.removeAll { schedule in
            uuids.contains(schedule.id)
        }
    }

    // Delete by IndexSet
    func deletenotexecuted(_ uuids: Set<UUID>) {
        globaltimer.notExecutedSchedulesafterWakeUp.removeAll { schedule in
            uuids.contains(schedule.id)
        }
    }
}
