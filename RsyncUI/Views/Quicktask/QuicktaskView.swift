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
                                ToggleView("--dry-run", $dryrun)

                                ToggleView("Don´t add /", $donotaddtrailingslash)
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
                    AlertToast(type: .complete(Color.green), title: Optional("Executed"), subTitle: Optional(""))
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

                    Button("Execute") { getconfig() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button("View") { presentoutput() }
                        .buttonStyle(PrimaryButtonStyle())
                        .sheet(isPresented: $presentsheetview) { viewoutput }

                    Button("Abort") { abort() }
                        .buttonStyle(AbortButtonStyle())
                }
            }
        }
        .lineSpacing(2)
        .padding()
    }

    var pickerselecttypeoftask: some View {
        Picker("Task" + ":",
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
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(300, "Add local catalog - required", $localcatalog)

            // remotecatalog
            EditValue(300, "Add remote catalog - required", $remotecatalog)
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(300, "Add remote as local catalog - required", $localcatalog)

            // remotecatalog
            EditValue(300, "Add local as remote catalog - required", $remotecatalog)
        }
    }

    var setremoteuser: some View {
        EditValue(300, "Add remote user", $remoteuser)
    }

    var setremoteserver: some View {
        EditValue(300, "Add remote server", $remoteserver)
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(300, "Add remote user", $remoteuser)
            // Remote server
            EditValue(300, "Add remote server", $remoteserver)
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
