//
//  rsyncUIdata.swift
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
    // TODO: remove
    var scheduleData: SchedulesSwiftUI?

    init(profile: String?) {
        self.profile = profile
        configurationData = ConfigurationsSwiftUI(profile: self.profile)
        validhiddenIDs = configurationData.getvalidhiddenIDs() ?? Set()
        // scheduleData = SchedulesSwiftUI(profile: self.profile, validhiddenIDs: validhiddenIDs)
    }
}

final class RsyncUIdata: ObservableObject {
    @Published var rsyncdata: Readdatafromstore?
    var configurations: [Configuration]?
    var profile: String?

    // var schedulesandlogs: [ConfigurationSchedule]?
    // var alllogssorted: [Log]?
    var validhiddenIDs: Set<Int>?

    /*
     func filterlogs(_ filter: String) -> [Log]? {
         // Important - must localize search in dates
         return alllogssorted?.filter {
             filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                 filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
         }
     }

     func filterlogsbyhiddenID(_ filter: String, _ hiddenID: Int) -> [Log]? {
         var joined: [Log]?
         guard hiddenID > -1 else { return nil }
         let schedulerecords = schedulesandlogs?.filter { $0.hiddenID == hiddenID }
         if (schedulerecords?.count ?? 0) > 0 {
             joined = [Log]()
             for i in 0 ..< (schedulerecords?.count ?? 0) {
                 if let logrecords = schedulerecords?[i].logrecords {
                     joined?.append(contentsOf: logrecords)
                 }
             }
             return joined?.sorted(by: \.date, using: >).filter {
                 filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                     filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
             }
         }
         return nil
     }

     func filterlogsbyUUIDs(_ uuids: Set<UUID>) -> [Log]? {
         return alllogssorted?.filter { uuids.contains($0.id) }.sorted(by: \.date, using: >)
     }
      */

    func filterconfigurations(_ filter: String) -> [Configuration]? {
        return configurations?.filter {
            filter.isEmpty ? true : $0.backupID.contains(filter)
        }
    }

    init(profile: String?) {
        guard SharedReference.shared.reload == true else {
            SharedReference.shared.reload = true
            return
        }
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            rsyncdata = Readdatafromstore(profile: nil)
        } else {
            rsyncdata = Readdatafromstore(profile: profile)
        }
        configurations = rsyncdata?.configurationData.getallconfigurations()
        // schedulesandlogs = rsyncdata?.scheduleData.getschedules()
        // alllogssorted = rsyncdata?.scheduleData.getalllogs()
        validhiddenIDs = rsyncdata?.validhiddenIDs
    }
}
