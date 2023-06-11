//
//  RsyncParametersView.swift
//  RsyncParametersView
//
//  Created by Thomas Evensen on 18/08/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @StateObject var parameters = ObserveableParametersRsync()
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var rsyncoutput: InprogressCountRsyncOutput?

    @State private var showprogressview = false
    @State private var presentsheetview = false
    @State private var valueselectedrow: String = ""
    @State private var numberoffiles: Int = 0
    @State private var selecteduuids = Set<Configuration.ID>()

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
                        EditRsyncParameter(450, $parameters.parameter9)
                        EditRsyncParameter(450, $parameters.parameter10)
                        EditRsyncParameter(450, $parameters.parameter11)
                        EditRsyncParameter(450, $parameters.parameter12)
                        EditRsyncParameter(450, $parameters.parameter13)
                        EditRsyncParameter(450, $parameters.parameter14)

                        Spacer()
                    }

                    if showtableview {
                        ListofTasksLightView(
                            selecteduuids: $selecteduuids.onChange {
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
                        )
                        .frame(maxWidth: .infinity)

                    } else {
                        notifyupdated
                    }

                    if focusaborttask { labelaborttask }
                }

                HStack {
                    RsyncCommandView(config: $parameters.configuration,
                                     selectedrsynccommand: $selectedrsynccommand)

                    Spacer()
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

                    if showprogressview { ProgressView() }

                    Spacer()

                    Button("Verify") {
                        if let configuration = parameters.updatersyncparameters() {
                            Task {
                                await verify(config: configuration)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Save") { saversyncparameters() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .focusedSceneValue(\.aborttask, $focusaborttask)
                .sheet(isPresented: $presentsheetview) { viewoutput }
                .padding()
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
        AlertToast(type: .complete(Color.green),
                   title: Optional("Updated"), subTitle: Optional(""))
            .onAppear(perform: {
                // Show updated for 3 seconds
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
                UpdateConfigurations(profile: rsyncUIdata.configurationsfromstore?.profile,
                                     configurations: rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.reset()
        selectedconfig = nil
        reload = true
        showtableview = false
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
        rsyncoutput = InprogressCountRsyncOutput(outputprocess: OutputfromProcess())
        showprogressview = true
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processtermination)
        await process.executeProcess()
    }

    func processtermination(outputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        rsyncoutput?.setoutput(data: outputfromrsync)
        presentsheetview = true
    }

    func abort() {
        showprogressview = false
        _ = InterruptProcess()
    }
}
