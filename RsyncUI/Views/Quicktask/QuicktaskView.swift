//
//  QuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

enum TypeofTaskQuictask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct QuicktaskView: View {
    @State private var localcatalog: String = ""
    @State private var remotecatalog: String = ""
    @State private var selectedrsynccommand = TypeofTaskQuictask.synchronize
    @State private var remoteuser: String = ""
    @State private var remoteserver: String = ""
    @State private var donotaddtrailingslash: Bool = false
    @State private var dryrun: Bool = true

    // Executed labels
    @State private var executed = false
    @State private var presentsheetview = false
    @State private var showprogressview = false
    @State private var rsyncoutput: InprogressCountRsyncOutput?
    // Selected row in output
    @State private var valueselectedrow: String = ""

    var body: some View {
        Form {
            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            pickerselecttypeoftask

                            HStack {
                                ToggleView(NSLocalizedString("--dry-run", comment: "ssh"), $dryrun)

                                ToggleView(NSLocalizedString("Don´t add /", comment: "settings"), $donotaddtrailingslash)
                            }
                        }

                        VStack(alignment: .leading) {
                            if selectedrsynccommand == .synchronize {
                                localandremotecatalog
                            } else {
                                localandremotecatalogsyncremote
                            }

                            remoteuserandserver
                        }
                    }

                    // For center
                    Spacer()
                }

                if executed == true {
                    AlertToast(type: .complete(Color.green), title: Optional(NSLocalizedString("Executed",
                                                                                               comment: "settings")), subTitle: Optional(""))
                }

                if showprogressview {
                    RotatingDotsIndicatorView()
                        .frame(width: 50.0, height: 50.0)
                        .foregroundColor(.red)
                }
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button(NSLocalizedString("Execute", comment: "QuicktaskView")) { getconfig() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button(NSLocalizedString("View", comment: "QuicktaskView")) { presentoutput() }
                        .buttonStyle(PrimaryButtonStyle())
                        .sheet(isPresented: $presentsheetview) { viewoutput }

                    Button(NSLocalizedString("Abort", comment: "RestoreView")) { abort() }
                        .buttonStyle(AbortButtonStyle())
                }
            }
        }
        .lineSpacing(2)
        .padding()
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Task", comment: "QuicktaskView") + ":",
               selection: $selectedrsynccommand.onChange {
                   resetform()
               }) {
            ForEach(TypeofTaskQuictask.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text(NSLocalizedString("Catalog parameters", comment: "QuicktaskView"))
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(250, NSLocalizedString("Add local catalog - required", comment: "QuicktaskView"), $localcatalog)

            // remotecatalog
            EditValue(250, NSLocalizedString("Add remote catalog - required", comment: "QuicktaskView"), $remotecatalog)
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(250, NSLocalizedString("Add remote as localcatalog - required", comment: "QuicktaskView"), $localcatalog)

            // remotecatalog
            EditValue(250, NSLocalizedString("Add local as remotecatalog - required", comment: "QuicktaskView"), $remotecatalog)
        }
    }

    var setremoteuser: some View {
        EditValue(250, NSLocalizedString("Add remote user", comment: "QuicktaskView"), $remoteuser)
    }

    var setremoteserver: some View {
        EditValue(250, NSLocalizedString("Add remote server", comment: "QuicktaskView"), $remoteserver)
    }

    var headerremote: some View {
        Text(NSLocalizedString("Remote parameters", comment: "QuicktaskView"))
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(250, NSLocalizedString("Add remote user", comment: "QuicktaskView"), $remoteuser)
            // Remote server
            EditValue(250, NSLocalizedString("Add remote server", comment: "QuicktaskView"), $remoteserver)
        }
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetview,
                        valueselectedrow: $valueselectedrow,
                        output: rsyncoutput?.getoutput() ?? [])
    }
}

extension QuicktaskView {
    func resetform() {
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
    }

    // Set output from rsync
    func presentoutput() {
        presentsheetview = true
    }

    func getconfig() {
        let getdata = AppendConfig(selectedrsynccommand.rawValue,
                                   localcatalog,
                                   remotecatalog,
                                   donotaddtrailingslash,
                                   remoteuser,
                                   remoteserver,
                                   "",
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   nil)
        // If newconfig is verified add it
        if let newconfig = VerifyConfiguration().verify(getdata) {
            // Now can prepare for execute.
            execute(config: newconfig, dryrun: dryrun)
        }
    }

    func execute(config: Configuration, dryrun: Bool) {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: dryrun, forDisplay: false)
        rsyncoutput = InprogressCountRsyncOutput(outputprocess: OutputfromProcess())
        // Start progressview
        showprogressview = true
        let command = RsyncProcess(arguments: arguments,
                                   config: nil,
                                   processtermination: processtermination,
                                   filehandler: filehandler)
        command.executeProcess(outputprocess: rsyncoutput?.myoutputprocess)
    }

    func abort() {
        _ = InterruptProcess()
    }

    func processtermination() {
        // Stop progressview
        showprogressview = false
        rsyncoutput?.setoutput()
        executed = true
        // Show updated for 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            executed = false
        }
    }

    func filehandler() {}
}
