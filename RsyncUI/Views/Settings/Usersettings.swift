//
//  Usersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import OSLog
import SwiftUI

struct Usersettings: View {
    @Environment(AlertError.self) private var alerterror
    @State private var usersettings = ObservableUsersetting()
    @State private var rsyncversion = Rsyncversion()
    @State private var configurationsarebackedup: Bool = false
    // Rsync paths
    @State private var defaultpathrsync = SetandValidatepathforrsync().getpathforrsync()

    var body: some View {
        HStack {
            // Column 1
            VStack(alignment: .leading) {
                Section(header: headerrsync) {
                    HStack {
                        ToggleViewDefault(NSLocalizedString("Rsync v3.x", comment: ""),
                                          $usersettings.rsyncversion3)
                            .onChange(of: usersettings.rsyncversion3) {
                                SharedReference.shared.rsyncversion3 = usersettings.rsyncversion3
                                rsyncversion.getrsyncversion()
                                defaultpathrsync = SetandValidatepathforrsync().getpathforrsync()
                            }

                        ToggleViewDefault(NSLocalizedString("Apple Silicon", comment: ""),
                                          $usersettings.macosarm)
                            .onChange(of: usersettings.macosarm) {
                                SharedReference.shared.macosarm = usersettings.macosarm
                            }
                            .disabled(true)
                    }
                }

                if usersettings.localrsyncpath.isEmpty == true {
                    setrsyncpathdefault
                } else {
                    setrsyncpathlocalpath
                }

                Section(header: headerpathforrestore) {
                    setpathforrestore
                }

                setmarkdays
            }

            // Column 2
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Section(header: othersettings) {
                        ToggleViewDefault(NSLocalizedString("Monitor network", comment: ""), $usersettings.monitornetworkconnection)
                            .onChange(of: usersettings.monitornetworkconnection) {
                                SharedReference.shared.monitornetworkconnection = usersettings.monitornetworkconnection
                            }
                        ToggleViewDefault(NSLocalizedString("Check for error in output", comment: ""), $usersettings.checkforerrorinrsyncoutput)
                            .onChange(of: usersettings.checkforerrorinrsyncoutput) {
                                SharedReference.shared.checkforerrorinrsyncoutput = usersettings.checkforerrorinrsyncoutput
                            }
                        ToggleViewDefault(NSLocalizedString("Add summary to logfile", comment: ""), $usersettings.detailedlogging)
                            .onChange(of: usersettings.detailedlogging) {
                                SharedReference.shared.detailedlogging = usersettings.detailedlogging
                            }
                        ToggleViewDefault(NSLocalizedString("Log summary to file", comment: ""),
                                          $usersettings.logtofile)
                            .onChange(of: usersettings.logtofile) {
                                SharedReference.shared.logtofile = usersettings.logtofile
                            }

                        if SharedReference.shared.rsyncversion3 {
                            ToggleViewDefault(NSLocalizedString("Confirm execute", comment: ""), $usersettings.confirmexecute)
                                .onChange(of: usersettings.confirmexecute) {
                                    SharedReference.shared.confirmexecute = usersettings.confirmexecute
                                }
                        }
                    }
                }
            }
        }
        .lineSpacing(2)
        .alert(isPresented: $usersettings.alerterror,
               content: { Alert(localizedError: usersettings.error)
               })
        .toolbar {
            ToolbarItem {
                Button {
                    _ = Backupconfigfiles()
                    configurationsarebackedup = true
                    Task {
                        try await Task.sleep(seconds: 2)
                        configurationsarebackedup = false
                    }

                } label: {
                    Image(systemName: "wrench.adjustable.fill")
                        .foregroundColor(Color(.blue))
                        .imageScale(.large)
                }
                .help("Backup configurations")
            }

            ToolbarItem {
                if SharedReference.shared.settingsischanged && usersettings.ready { thumbsupgreen }
            }

            ToolbarItem {
                if configurationsarebackedup { thumbsupgreen }
            }
        }
        .onAppear(perform: {
            Task {
                try await Task.sleep(seconds: 1)
                Logger.process.info("Usersettings is DEFAULT")
                SharedReference.shared.settingsischanged = false
                usersettings.ready = true
            }
        })
        .onChange(of: SharedReference.shared.settingsischanged) {
            guard SharedReference.shared.settingsischanged == true,
                  usersettings.ready == true else { return }
            Task {
                try await Task.sleep(seconds: 1)
                _ = WriteUserConfigurationJSON(UserConfiguration())
                SharedReference.shared.settingsischanged = false
                Logger.process.info("Usersettings is SAVED")
            }
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup")
            .foregroundColor(Color(.green))
            .padding()
    }

    // Rsync
    var headerrsync: some View {
        Text("Rsync version and path")
    }

    var setrsyncpathlocalpath: some View {
        EditValue(250, nil, $usersettings.localrsyncpath)
            .onAppear(perform: {
                usersettings.localrsyncpath = SetandValidatepathforrsync().getpathforrsync()
            })
    }

    var setrsyncpathdefault: some View {
        EditValue(250, defaultpathrsync, $usersettings.localrsyncpath)
            .onChange(of: usersettings.localrsyncpath) {
                usersettings.setandvalidatepathforrsync(usersettings.localrsyncpath)
            }
    }

    // Restore path
    var headerpathforrestore: some View {
        Text("Path for restore")
    }

    var setpathforrestore: some View {
        EditValue(250, NSLocalizedString("Path for restore", comment: ""),
                  $usersettings.temporarypathforrestore)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    usersettings.temporarypathforrestore = pathforrestore
                }
            })
            .onChange(of: usersettings.temporarypathforrestore) {
                usersettings.setandvalidapathforrestore(usersettings.temporarypathforrestore)
            }
    }

    // Detail of logging
    var othersettings: some View {
        Text("Other settings")
    }

    // Header user setting
    var headerusersetting: some View {
        Text("Save settings")
    }

    var setmarkdays: some View {
        HStack {
            Text("Mark days :")

            TextField("",
                      text: $usersettings.marknumberofdayssince)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 45)
                .lineLimit(1)
                .onChange(of: usersettings.marknumberofdayssince) {
                    usersettings.markdays(days: usersettings.marknumberofdayssince)
                }
        }
    }
}

// swiftlint:enable line_length
