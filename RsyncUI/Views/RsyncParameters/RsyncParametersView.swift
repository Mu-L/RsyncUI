//
//  RsyncParametersView.swift
//  RsyncParametersView
//
//  Created by Thomas Evensen on 18/08/2021.
//

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @StateObject var parameters = ObserveableParametersRsync()
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var presentrsynccommandoview = false

    @State private var searchText: String = ""
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    EditRsyncParameter(450, $parameters.parameter8)
                    EditRsyncParameter(450, $parameters.parameter9)
                    EditRsyncParameter(450, $parameters.parameter10)
                    EditRsyncParameter(450, $parameters.parameter11)
                    EditRsyncParameter(450, $parameters.parameter12)
                    EditRsyncParameter(450, $parameters.parameter13)
                    EditRsyncParameter(450, $parameters.parameter14)

                    Spacer()
                }

                ConfigurationsListSmall(selectedconfig: $selectedconfig.onChange {
                    parameters.configuration = selectedconfig
                },
                reload: $reload)
            }

            Spacer()

            HStack {
                Button("Linux") {
                    parameters.suffixlinux = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("FreeBSD") {
                    parameters.suffixfreebsd = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Backup") {
                    parameters.backup = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Spacer()

                Button("Rsync") { presenteview() }
                    .buttonStyle(PrimaryButtonStyle())
                    .sheet(isPresented: $presentrsynccommandoview) {
                        RsyncCommandView(selectedconfig: $parameters.configuration,
                                         isPresented: $presentrsynccommandoview)
                    }

                Button("Save") { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = "Default profile"
            }
        })
    }
}

extension RsyncParametersView {
    func presenteview() {
        presentrsynccommandoview = true
    }

    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.rsyncdata?.profile,
                                     configurations: rsyncUIdata.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        selectedconfig = nil
        reload = true
    }
}
