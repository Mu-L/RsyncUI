//
//  SchedulesList.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 21/01/2021.
//

import SwiftUI

struct SchedulesList: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selectedconfig: Configuration?
    @Binding var selectedschedule: ConfigurationSchedule?
    @Binding var selecteduuids: Set<UUID>

    var body: some View {
        List(selection: $selectedschedule) {
            ForEach(activeschedulesandlogs) { record in
                ScheduleRow(selecteduuids: $selecteduuids, configschedule: record)
                    .tag(record)
            }
        }
    }

    var activeschedulesandlogs: [ConfigurationSchedule] {
        if let schedulesandlogs = rsyncUIdata.schedulesandlogs {
            return schedulesandlogs.filter { schedulesandlogs in selectedconfig?.hiddenID == schedulesandlogs.hiddenID
                && schedulesandlogs.dateStop == "01 Jan 2100 00:00"
            }
        } else {
            return []
        }
    }
}
