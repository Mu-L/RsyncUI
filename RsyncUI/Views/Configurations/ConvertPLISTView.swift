//
//  ConvertPLISTView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import SwiftUI

struct ConvertPLISTView: View {
    // @Binding var config: Configuration?
    @Binding var isPresented: Bool
    // Documents about convert
    var infoaboutconvert: String = "https://rsyncui.netlify.app/post/plist/"
    @State private var convertisready: Bool = false
    @State private var jsonfileexists: Bool = false
    @State private var convertisconfirmed: Bool = false
    @State private var convertcompleted: Bool = false

    @State private var backup: Bool = false

    var body: some View {
        VStack {
            Text(NSLocalizedString("Output from rsync", comment: "OutputRsyncView"))
                .font(.title2)
                .padding()

            if convertisready {
                HStack {
                    Spacer()

                    prepareconvertplist

                    Spacer()
                }

                HStack {
                    Spacer()

                    if jsonfileexists { alertjsonfileexists }

                    Spacer()
                }
            }

            if convertcompleted == true {
                AlertToast(type: .complete(Color.green),
                           title: Optional(NSLocalizedString("Completed",
                                                             comment: "settings")), subTitle: Optional(""))
                    .onAppear(perform: {
                        // Show updated for 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            convertcompleted = false
                        }
                    })
            }

            if backup == true {
                AlertToast(type: .complete(Color.green),
                           title: Optional(NSLocalizedString("Saved",
                                                             comment: "settings")), subTitle: Optional(""))
                    .onAppear(perform: {
                        // Show updated for 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            backup = false
                        }
                    })
            }

            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .onAppear(perform: {
            convertisready = false
        })
    }

    var prepareconvertplist: some View {
        HStack {
            Button(NSLocalizedString("Info about convert", comment: "Othersettings")) { openinfo() }
                .buttonStyle(PrimaryButtonStyle())

            ToggleView(NSLocalizedString("Confirm convert", comment: "Othersettings"), $convertisconfirmed)

            if convertisconfirmed {
                VStack {
                    // Backup configuration files
                    Button(NSLocalizedString("Backup", comment: "usersetting")) { backupuserconfigs() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button(NSLocalizedString("Convert", comment: "Othersettings")) { convert() }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    var alertjsonfileexists: some View {
        AlertToast(type: .error(Color.red), title: Optional("JSON file exists"), subTitle: Optional(""))
    }

    var convertbutton: some View {
        Button(NSLocalizedString("PLIST", comment: "Othersettings")) { verifyconvert() }
            .buttonStyle(PrimaryButtonStyle())
    }

    func verifyconvert() {
        /*
         let configs = ReadConfigurationsPLIST(rsyncUIData.profile)
         if configs.thereisplistdata == true {
             convertisready = true
         }
         if configs.jsonfileexist == true {
             jsonfileexists = true
         }
         */
    }

    func convert() {
        /*
         let configs = ReadConfigurationsPLIST(rsyncUIData.profile)
         let schedules = ReadSchedulesPLIST(rsyncUIData.profile)
         if convertisconfirmed {
             configs.writedatatojson()
             schedules.writedatatojson()
         }
         convertisready = false
         jsonfileexists = false
         convertisconfirmed = false
         convertcompleted = true
         */
    }

    func openinfo() {
        NSWorkspace.shared.open(URL(string: infoaboutconvert)!)
    }

    func backupuserconfigs() {
        _ = Backupconfigfiles()
        backup = true
    }

    func dismissview() {
        isPresented = false
    }
}
