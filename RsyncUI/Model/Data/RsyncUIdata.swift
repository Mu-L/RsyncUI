//
//  rsyncUIData.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import SwiftUI

struct Readdatafromstore {
    var profile: String?
    var configurationData: ConfigurationsSwiftUI
    var validhiddenIDs: Set<Int>
    var scheduleData: SchedulesSwiftUI

    init(profile: String?) {
        self.profile = profile
        configurationData = ConfigurationsSwiftUI(profile: self.profile)
        validhiddenIDs = configurationData.getvalidhiddenIDs() ?? Set()
        scheduleData = SchedulesSwiftUI(profile: self.profile, validhiddenIDs: validhiddenIDs)
    }
}

final class RsyncUIdata: ObservableObject {
    @Published var rsyncdata: Readdatafromstore?
    @Published var configurations: [Configuration]?
    @Published var schedulesandlogs: [ConfigurationSchedule]?
    @Published var profile: String?
    // All logs and sorted logs
    // Sort and filter logs so the view does not trigger a refresh
    var alllogssorted: [Log]?
    var filterlogsorted: [Log]?
    var filterlogsortedbyhiddenID: [Log]?

    func filter(_ filter: String) {
        // Important - must localize search in dates
        filterlogsorted = alllogssorted?.filter {
            filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
        }
    }

    func filterbyhiddenID(_ filter: String, _ hiddenID: Int) {
        // Important - must localize search in dates
        filterlogsortedbyhiddenID = rsyncdata?.scheduleData.getalllogsbyhiddenID(hiddenID: hiddenID)?.filter {
            filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
        }
    }

    func activeschedules(_ hiddenID: Int) -> Int {
        return rsyncdata?.scheduleData.getallactiveshedulesbyhiddenID(hiddenID: hiddenID) ?? 0
    }

    func update() {
        objectWillChange.send()
    }

    init(profile: String?) {
        self.profile = profile
        if profile == NSLocalizedString("Default profile", comment: "default profile") || profile == nil {
            rsyncdata = Readdatafromstore(profile: nil)
        } else {
            rsyncdata = Readdatafromstore(profile: profile)
        }
        configurations = rsyncdata?.configurationData.getallconfigurations()
        schedulesandlogs = rsyncdata?.scheduleData.getschedules()
        alllogssorted = rsyncdata?.scheduleData.getalllogs()
        filterlogsorted = alllogssorted
        filterlogsortedbyhiddenID = alllogssorted
        objectWillChange.send()
    }
}
