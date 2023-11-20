//
//  NavigationRsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct NavigationRsyncParametersView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var parameters = ObservableParametersRsync()

    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var rsyncoutput: ObservableRsyncOutput?

    @State private var showprogressview = false
    @State private var presentsheetview = false
    @State private var valueselectedrow: String = ""
    @State private var numberoffiles: Int = 0
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var dataischanged = Dataischanged()

    @State private var selectedrsynccommand = RsyncCommand.synchronize

    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        EditRsyncParameter(450, $parameters.parameter8)
                            .onChange(of: parameters.parameter8) {
                                parameters.configuration?.parameter8 = parameters.parameter8
                            }
                        EditRsyncParameter(450, $parameters.parameter9)
                            .onChange(of: parameters.parameter9) {
                                parameters.configuration?.parameter9 = parameters.parameter9
                            }
                        EditRsyncParameter(450, $parameters.parameter10)
                            .onChange(of: parameters.parameter10) {
                                parameters.configuration?.parameter10 = parameters.parameter10
                            }
                        EditRsyncParameter(450, $parameters.parameter11)
                            .onChange(of: parameters.parameter11) {
                                parameters.configuration?.parameter11 = parameters.parameter11
                            }
                        EditRsyncParameter(450, $parameters.parameter12)
                            .onChange(of: parameters.parameter12) {
                                parameters.configuration?.parameter12 = parameters.parameter12
                            }
                        EditRsyncParameter(450, $parameters.parameter13)
                            .onChange(of: parameters.parameter13) {
                                parameters.configuration?.parameter13 = parameters.parameter13
                            }
                        EditRsyncParameter(450, $parameters.parameter14)
                            .onChange(of: parameters.parameter14) {
                                parameters.configuration?.parameter14 = parameters.parameter14
                            }

                        Spacer()
                    }

                    ListofTasksLightView(selecteduuids: $selecteduuids)
                        .frame(maxWidth: .infinity)
                        .onChange(of: selecteduuids) {
                            let selected = rsyncUIdata.configurations?.filter { config in
                                selecteduuids.contains(config.id)
                            }
                            if (selected?.count ?? 0) == 1 {
                                if let config = selected {
                                    selectedconfig = config[0]
                                    parameters.setvalues(selectedconfig)
                                }
                            } else {
                                selectedconfig = nil
                                parameters.setvalues(selectedconfig)
                            }
                        }

                    if focusaborttask { labelaborttask }
                }

                ZStack {
                    HStack {
                        RsyncCommandView(config: $parameters.configuration,
                                         selectedrsynccommand: $selectedrsynccommand)

                        Spacer()
                    }

                    if showprogressview { AlertToast(displayMode: .alert, type: .loading) }
                }

                Spacer()

                HStack {
                    Button("Linux") {
                        parameters.setsuffixlinux()
                    }
                    .buttonStyle(ColorfulButtonStyle())

                    Button("FreeBSD") {
                        parameters.setsuffixfreebsd()
                    }
                    .buttonStyle(ColorfulButtonStyle())

                    Button("Backup") {
                        parameters.setbackup()
                    }
                    .buttonStyle(ColorfulButtonStyle())

                    Spacer()

                    Button("Verify") {
                        if let configuration = parameters.updatersyncparameters() {
                            Task {
                                await verify(config: configuration)
                            }
                        }
                    }
                    .buttonStyle(ColorfulButtonStyle())

                    Button("Save") { saversyncparameters() }
                        .buttonStyle(ColorfulButtonStyle())
                }
                .focusedSceneValue(\.aborttask, $focusaborttask)
                // .sheet(isPresented: $presentsheetview) { viewoutput }
                .padding()
                .onAppear {
                    if dataischanged.dataischanged {
                        dataischanged.dataischanged = false
                    }
                }
                .alert(isPresented: $parameters.alerterror,
                       content: { Alert(localizedError: parameters.error)
                       })
            }
        }
        .navigationDestination(isPresented: $presentsheetview) {
            OutputRsyncView(output: rsyncoutput?.getoutput() ?? [])
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }
}

/*
 let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                       outputfromrsync: outputfromrsync,
                                       config: localconfigurations?.getconfig(hiddenID: hiddenID ?? -1))
 */
extension NavigationRsyncParametersView {
    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: rsyncUIdata.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.reset()
        selectedconfig = nil
        reload = true
        dataischanged.dataischanged = true
    }

    func verify(config: Configuration) async {
        var arguments: [String]?
        switch selectedrsynccommand {
        case .synchronize:
            arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: false)
        case .restore:
            arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: false, tmprestore: true)
        case .verify:
            arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: false)
        }
        rsyncoutput = ObservableRsyncOutput()
        showprogressview = true
        let process = await RsyncProcessAsync(arguments: arguments,
                                              config: config,
                                              processtermination: processtermination)
        await process.executeProcess()
    }

    func processtermination(outputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        rsyncoutput?.setoutput(outputfromrsync)
        presentsheetview = true
    }

    func abort() {
        showprogressview = false
        _ = InterruptProcess()
    }
}

// swiftlint:enable line_length
