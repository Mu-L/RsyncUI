//
//  Usersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Usersettings: View {
    @SwiftUI.Environment(AlertError.self) private var alerterror
    @State private var usersettings = ObservableUsersetting()
    @State private var backup = false
    @State private var rsyncversion = Rsyncversion()

    var body: some View {
        Form {
            Spacer()

            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        Section(header: headerrsync) {
                            HStack {
                                ToggleViewDefault(NSLocalizedString("Rsync v3.x", comment: ""),
                                                  $usersettings.rsyncversion3)
                                    .onChange(of: usersettings.rsyncversion3) {
                                        SharedReference.shared.rsyncversion3 = usersettings.rsyncversion3
                                    }

                                ToggleViewDefault(NSLocalizedString("Apple Silicon", comment: ""),
                                                  $usersettings.macosarm)
                                    .onChange(of: usersettings.macosarm) {
                                        SharedReference.shared.macosarm = usersettings.macosarm
                                    }
                            }
                        }

                        // Not working
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
                    .padding()

                    // Column 2
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading) {
                                Section(header: headerloggingtofile) {
                                    ToggleViewDefault(NSLocalizedString("None", comment: ""),
                                                      $usersettings.nologging)
                                        .onChange(of: usersettings.nologging) {
                                            if usersettings.nologging == true {
                                                usersettings.minimumlogging = false
                                                usersettings.fulllogging = false
                                            } else {
                                                usersettings.minimumlogging = true
                                                usersettings.fulllogging = false
                                            }
                                            SharedReference.shared.fulllogging = usersettings.fulllogging
                                            SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                            SharedReference.shared.nologging = usersettings.nologging
                                        }

                                    ToggleViewDefault(NSLocalizedString("Min", comment: ""),
                                                      $usersettings.minimumlogging)
                                        .onChange(of: usersettings.minimumlogging) {
                                            if usersettings.minimumlogging == true {
                                                usersettings.nologging = false
                                                usersettings.fulllogging = false
                                            }
                                            SharedReference.shared.fulllogging = usersettings.fulllogging
                                            SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                            SharedReference.shared.nologging = usersettings.nologging
                                        }

                                    ToggleViewDefault(NSLocalizedString("Full", comment: ""),
                                                      $usersettings.fulllogging)
                                        .onChange(of: usersettings.fulllogging) {
                                            if usersettings.fulllogging == true {
                                                usersettings.nologging = false
                                                usersettings.minimumlogging = false
                                            }
                                            SharedReference.shared.fulllogging = usersettings.fulllogging
                                            SharedReference.shared.minimumlogging = usersettings.minimumlogging
                                            SharedReference.shared.nologging = usersettings.nologging
                                        }
                                }
                            }

                            VStack(alignment: .leading) {
                                Section(header: othersettings) {
                                    ToggleViewDefault(NSLocalizedString("Detailed log level", comment: ""), $usersettings.detailedlogging)
                                        .onChange(of: usersettings.detailedlogging) {
                                            SharedReference.shared.detailedlogging = usersettings.detailedlogging
                                        }

                                    ToggleViewDefault(NSLocalizedString("Monitor network", comment: ""), $usersettings.monitornetworkconnection)
                                        .onChange(of: usersettings.monitornetworkconnection) {
                                            SharedReference.shared.monitornetworkconnection = usersettings.monitornetworkconnection
                                        }
                                    ToggleViewDefault(NSLocalizedString("Check for error in output", comment: ""), $usersettings.checkforerrorinrsyncoutput)
                                        .onChange(of: usersettings.checkforerrorinrsyncoutput) {
                                            SharedReference.shared.checkforerrorinrsyncoutput = usersettings.checkforerrorinrsyncoutput
                                        }
                                    /*
                                                                        HStack {
                                                                            ToggleViewDefault(NSLocalizedString("Automatic execute :", comment: ""), $usersettings.automaticexecute)
                                                                                .onChange(of: usersettings.automaticexecute) {
                                                                                    SharedReference.shared.automaticexecute = usersettings.automaticexecute
                                                                                }

                                                                            setautomaticexecutetime
                                                                        }
                                     */
                                }
                            }
                        }
                    }
                    .padding()

                    // For center
                    Spacer()
                }

                if backup == true {
                    AlertToast(type: .complete(Color.green),
                               title: Optional(NSLocalizedString("Saved", comment: "")), subTitle: Optional(""))
                        .onAppear(perform: {
                            // Show updated for 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                backup = false
                            }
                        })
                }
            }

            Spacer()
        }
        .lineSpacing(2)
        .padding()
        .alert(isPresented: $usersettings.alerterror,
               content: { Alert(localizedError: usersettings.error)
               })
        .toolbar {
            ToolbarItem {
                Button {
                    backupuserconfigs()
                } label: {
                    Image(systemName: "wrench.adjustable")
                        .foregroundColor(Color(.blue))
                }
                .help("Backup configurations")
            }

            ToolbarItem {
                Button {
                    saveusersettings()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(Color(.blue))
                }
                .help("Save usersettings")
            }
        }
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
        EditValue(250, SetandValidatepathforrsync().getpathforrsync(),
                  $usersettings.localrsyncpath)
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

    // Logging
    var headerloggingtofile: some View {
        Text("Log to file")
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

    var setautomaticexecutetime: some View {
        TextField("",
                  text: $usersettings.automaticexecutetime)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 45)
            .lineLimit(1)
            .onChange(of: usersettings.automaticexecutetime) {
                usersettings.automaticexecute(seconds: usersettings.automaticexecutetime)
            }
    }
}

extension Usersettings {
    func saveusersettings() {
        _ = WriteUserConfigurationJSON(UserConfiguration())
        // Update the rsync version string
        Task {
            await rsyncversion.getrsyncversion()
        }
        backup = true
    }

    func backupuserconfigs() {
        _ = Backupconfigfiles()
        backup = true
    }
}

// swiftlint:enable line_length
