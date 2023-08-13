//
//  RsyncParametersView.swift
//  RsyncParametersView
//
//  Created by Thomas Evensen on 18/08/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RsyncParametersView: View {
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

    // Reload and show table data
    @State private var showtableview: Bool = true

    var body: some View {
        ZStack {
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

                    if showtableview {
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

                    } else {
                        notifyupdated
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
                        parameters.suffixlinux = true
                    }
                    .buttonStyle(ColorfulButtonStyle())
                    .onChange(of: parameters.suffixlinux) {
                        parameters.setsuffixlinux()
                    }

                    Button("FreeBSD") {
                        parameters.suffixfreebsd = true
                    }
                    .buttonStyle(ColorfulButtonStyle())
                    .onChange(of: parameters.suffixfreebsd) {
                        parameters.setsuffixfreebsd()
                    }

                    Button("Backup") {
                        parameters.backup = true
                    }
                    .buttonStyle(ColorfulButtonStyle())
                    .onChange(of: parameters.backup) {
                        parameters.setbackup()
                    }

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
                .sheet(isPresented: $presentsheetview) { viewoutput }
                .padding()
                .onAppear {
                    if dataischanged.dataischanged {
                        showtableview = false
                        dataischanged.dataischanged = false
                    }
                }
            }
        }
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(output: rsyncoutput?.getoutput() ?? [])
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var notifyupdated: some View {
        notifymessage("Updated")
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showtableview = true
                }
            })
            .frame(maxWidth: .infinity)
    }
}

extension RsyncParametersView {
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
        showtableview = false
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
