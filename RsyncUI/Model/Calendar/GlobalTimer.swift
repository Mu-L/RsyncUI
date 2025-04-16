//
//  GlobalTimer.swift
//  Calendar
//
//  Created by Thomas Evensen on 31/03/2025.
//

import Foundation
import Observation

@Observable
final class GlobalTimer {
    @MainActor static let shared = GlobalTimer()

    private init() {}

    private var timer: Timer?
    private var schedules: [String: (time: Date, callback: () -> Void)] = [:]

    func addSchedule(name: String, time: Date, callback: @escaping () -> Void) {
        schedules[name] = (time, callback)
        start()
    }

    func removeSchedule(name: String) {
        schedules.removeValue(forKey: name)
        if schedules.isEmpty {
            timer?.invalidate()
            timer = nil
        }
    }

    private func start() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(checkSchedules),
                                         userInfo: nil,
                                         repeats: false)
        }
    }

    @objc private func checkSchedules() {
        let now = Date()
        for (name, schedule) in schedules {
            if now >= schedule.time {
                schedule.callback()
                removeSchedule(name: name)
            }
        }
    }
}

/*
 // Usage example
 let globalTimer = GlobalTimer.shared

 let dateFormatter = DateFormatter()
 dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

 if let meetingTime = dateFormatter.date(from: "2025-03-31 15:00:00") {
     globalTimer.addSchedule(name: "Meeting", time: meetingTime) {
         print("Meeting time!")
     }
 }

 if let lunchTime = dateFormatter.date(from: "2025-03-31 12:00:00") {
     globalTimer.addSchedule(name: "Lunch", time: lunchTime) {
         print("Lunch time!")
     }
 }
 */
// To remove a schedule
// globalTimer.removeSchedule(name: "Lunch")


