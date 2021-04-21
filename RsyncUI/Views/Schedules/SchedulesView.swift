//
//  SchedulesView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/03/2021.
//

import SwiftUI

struct SchedulesView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var selectedschedule: ConfigurationSchedule?
    @State private var selecteduuids = Set<UUID>()

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false

    // Datepicker
    @State private var selecteddate = Date()
    @State private var selectedscheduletype = EnumScheduleDatePicker.once

    // Alert for delete
    @State private var showAlertfordelete = false

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig.onChange { rsyncUIData.update() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)
        HStack {
            VStack {
                HStack {
                    SelectedstartView(selecteddate: $selecteddate,
                                      selectedscheduletype: $selectedscheduletype)
                        .padding(1)
                        .border(Color.gray)

                    Button(NSLocalizedString("Add", comment: "Add button")) { addschedule() }
                        .buttonStyle(PrimaryButtonStyle())
                }

                SchedulesList(selectedconfig: $selectedconfig.onChange { rsyncUIData.update() },
                              selectedschedule: $selectedschedule,
                              selecteduuids: $selecteduuids)
                    .border(Color.gray)
            }

            SchedulesDatePickerView(selecteddate: $selecteddate)
        }
        .padding()
        // Buttons in right down corner
        Spacer()

        HStack {
            Spacer()

            Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Stop", comment: "Stop button")) { stop() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Delete", comment: "Delete button")) { delete() }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $showAlertfordelete) {
                    DeleteSchedulesView(selecteduuids: $selecteduuids,
                                        isPresented: $showAlertfordelete,
                                        reload: $reload,
                                        selectedprofile: $selectedprofile)
                }
        }
    }
}

extension SchedulesView {
    func select() {
        if let schedule = selectedschedule {
            if selecteduuids.contains(schedule.id) {
                selecteduuids.remove(schedule.id)
            } else {
                selecteduuids.insert(schedule.id)
            }
        }
    }

    func setuuidforselectedschedule() {
        if let schedule = selectedschedule,
           let schedules = rsyncUIData.schedulesandlogs
        {
            if let index = schedules.firstIndex(of: schedule) {
                if let id = rsyncUIData.schedulesandlogs?[index].id {
                    selecteduuids.insert(id)
                }
            }
        }
    }

    func addschedule() {
        let addschedule = UpdateSchedules(profile: selectedprofile,
                                          scheduleConfigurations: rsyncUIData.schedulesandlogs)
        let add = addschedule.add(selectedconfig?.hiddenID,
                                  selectedscheduletype,
                                  selecteddate)
        if add == true {
            reload = true
        }
        selecteduuids.removeAll()
    }

    func stop() {
        if selecteduuids.count == 0 { setuuidforselectedschedule() }
        let stopschedule = UpdateSchedules(profile: selectedprofile,
                                           scheduleConfigurations: rsyncUIData.schedulesandlogs)
        stopschedule.stopschedule(uuids: selecteduuids)
        reload = true
        selecteduuids.removeAll()
    }

    func delete() {
        if selecteduuids.count == 0 { setuuidforselectedschedule() }
        guard selecteduuids.count > 0 else { return }
        showAlertfordelete = true
        // selecteduuids.removeAll() is done in sheetview
    }
}

enum Scheduletype: String {
    case once
    case daily
    case weekly
    case manuel
    case stopped
}
