//
//  QuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/11/2023.
//

import SwiftUI

enum TypeofTaskQuictask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

enum ValidateInputQuicktask: LocalizedError {
    case localcatalog
    case remotecatalog
    case offsiteusername
    case offsiteserver

    var errorDescription: String? {
        switch self {
        case .localcatalog:
            "Source folder cannot be empty"
        case .offsiteusername:
            "Remote username cannot be empty"
        case .remotecatalog:
            "Destination folder cannot be empty"
        case .offsiteserver:
            "Remote servername cannot be empty"
        }
    }
}

struct QuicktaskView: View {
    @State private var localcatalog: String = ""
    @State private var remotecatalog: String = ""
    @State private var selectedrsynccommand = TypeofTaskQuictask.synchronize
    @State private var remoteuser: String = ""
    @State private var remoteserver: String = ""
    @State private var trailingslashoptions: TrailingSlash = .add
    @State private var dryrun: Bool = true
    @State private var catalogorfile: Bool = true

    // Executed labels
    @State private var showprogressview = false
    @State private var rsyncoutput = ObservableRsyncOutput()
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false
    @State private var focusstartexecution: Bool = false
    // Completed task
    @State private var completed: Bool = false

    enum QuicktaskField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
    }

    @FocusState private var focusField: QuicktaskField?

    var body: some View {
        ZStack {
            Spacer()

            // Column 1
            VStack(alignment: .leading) {
                HStack {
                    pickerselecttypeoftask

                    VStack(alignment: .trailing) {
                        Toggle("--dry-run", isOn: $dryrun)
                            .toggleStyle(.switch)
                            .onTapGesture {
                                withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                    dryrun.toggle()
                                }
                            }

                        Toggle("File(off) or Folder(on)", isOn: $catalogorfile)
                            .toggleStyle(.switch)
                            .onChange(of: catalogorfile) {
                                if catalogorfile {
                                    trailingslashoptions = .do_not_add
                                } else {
                                    trailingslashoptions = .add
                                }
                            }
                            .onTapGesture {
                                withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                    catalogorfile.toggle()
                                }
                            }

                        trailingslash
                    }
                    .padding()
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

            if showprogressview { ProgressView() }
            if focusaborttask { labelaborttask }
            if focusstartexecution { labelstartexecution }
        }
        .onSubmit {
            switch focusField {
            case .localcatalogField:
                focusField = .remotecatalogField
            case .remotecatalogField:
                focusField = .remoteuserField
            case .remoteuserField:
                focusField = .remoteserverField
            case .remoteserverField:
                focusField = nil
                dryrun = true
            default:
                return
            }
        }
        .onAppear {
            focusField = .localcatalogField
            Task {
                if let configfile = await ActorReadSynchronizeQuicktaskJSON().readjsonfilequicktask() {
                    localcatalog = configfile.localCatalog
                    remotecatalog = configfile.offsiteCatalog
                    remoteuser = configfile.offsiteUsername
                    remoteserver = configfile.offsiteServer
                    if configfile.backupID == "1" {
                        selectedrsynccommand = .synchronize
                        trailingslashoptions = .add
                        catalogorfile = false
                    } else if configfile.backupID == "2" {
                        selectedrsynccommand = .syncremote
                        trailingslashoptions = .add
                        catalogorfile = false
                    } else if configfile.backupID == "3" {
                        selectedrsynccommand = .synchronize
                        trailingslashoptions = .do_not_add
                        catalogorfile = true
                    } else if configfile.backupID == "4" {
                        selectedrsynccommand = .syncremote
                        trailingslashoptions = .do_not_add
                        catalogorfile = true
                    }
                }
            }
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    resetform()
                    CatalogForProfile().deletefile()
                } label: {
                    if localcatalog.isEmpty == false {
                        Image(systemName: "clear")
                            .foregroundColor(Color(.red))
                    } else {
                        Image(systemName: "clear")
                    }
                }
                .help("Clear saved quicktask")
            }

            ToolbarItem {
                Button {
                    getconfigandexecute()
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Synchronize (⌘R)")
            }

            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
        .padding()
        .navigationTitle("Quicktask")
        .navigationDestination(isPresented: $completed) {
            OutputRsyncView(output: rsyncoutput.output ?? [])
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                getconfigandexecute()
            })
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Action", comment: "") + ":",
               selection: $selectedrsynccommand)
        {
            ForEach(TypeofTaskQuictask.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Folder parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            HStack {
                EditValueScheme(300, NSLocalizedString("Add Source folder - required", comment: ""), $localcatalog)
                    .focused($focusField, equals: .localcatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)
            }

            // remotecatalog
            HStack {
                EditValueScheme(300, NSLocalizedString("Add Destination folder - required", comment: ""), $remotecatalog)
                    .focused($focusField, equals: .remotecatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            // remotecatalog
            HStack {
                EditValueScheme(300, NSLocalizedString("Add Source folder - required", comment: ""), $remotecatalog)
                    .focused($focusField, equals: .remotecatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)
            }

            // localcatalog
            HStack {
                EditValueScheme(300, NSLocalizedString("Add Destination folder - required", comment: ""), $localcatalog)
                    .focused($focusField, equals: .localcatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)
            }
        }
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValueScheme(300, NSLocalizedString("Add remote user", comment: ""), $remoteuser)
                .focused($focusField, equals: .remoteuserField)
                .textContentType(.none)
                .submitLabel(.continue)
            // Remote server
            EditValueScheme(300, NSLocalizedString("Add remote server", comment: ""), $remoteserver)
                .focused($focusField, equals: .remoteserverField)
                .textContentType(.none)
                .submitLabel(.return)
        }
    }
    
    var trailingslash: some View {
        Picker(NSLocalizedString("Trailing /", comment: ""),
               selection: $trailingslashoptions)
        {
            ForEach(TrailingSlash.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 170)
    }
}

extension QuicktaskView {
    func resetform() {
        selectedrsynccommand = .synchronize
        trailingslashoptions = .add
        dryrun = true
        catalogorfile = true
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
    }

    func updatesavedtask(_ config: SynchronizeConfiguration) {
        var newconfig = config
        if selectedrsynccommand == .synchronize, trailingslashoptions == .add {
            newconfig.backupID = "1"
        } else if selectedrsynccommand == .syncremote, trailingslashoptions == .add  {
            newconfig.backupID = "2"
        } else if selectedrsynccommand == .synchronize, trailingslashoptions == .do_not_add {
            newconfig.backupID = "3"
        } else if selectedrsynccommand == .syncremote, trailingslashoptions == .do_not_add {
            newconfig.backupID = "4"
        }
        Task {
            await ActorWriteSynchronizeQuicktaskJSON(newconfig)
        }
    }

    func getconfigandexecute() {
        let getdata = AppendTask(selectedrsynccommand.rawValue,
                                 localcatalog,
                                 remotecatalog,
                                 trailingslashoptions,
                                 remoteuser,
                                 remoteserver,
                                 "")
        if let config = VerifyConfiguration().verify(getdata) {
            do {
                let ok = try validateinput(config)
                if ok {
                    execute(config: config, dryrun: dryrun)
                    updatesavedtask(config)
                }
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    func execute(config: SynchronizeConfiguration, dryrun: Bool) {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: dryrun, forDisplay: false)
        // Start progressview
        showprogressview = true
        let process = ProcessRsyncAsyncSequence(arguments: arguments,
                                                config: config,
                                                processtermination: processtermination)
        process.executeProcess()
    }

    func abort() {
        InterruptProcess()
    }

    func processtermination(_ stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        Task {
            rsyncoutput.output = await ActorCreateOutputforviewQuicktask().createaoutputforview(stringoutputfromrsync)
            completed = true
        }
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }

    private func validateinput(_ config: SynchronizeConfiguration) throws -> Bool {
        if config.localCatalog.isEmpty {
            throw ValidateInputQuicktask.localcatalog
        }
        if config.offsiteCatalog.isEmpty {
            throw ValidateInputQuicktask.remotecatalog
        }
        if config.offsiteServer.isEmpty {
            throw ValidateInputQuicktask.offsiteserver
        }
        if config.offsiteUsername.isEmpty {
            throw ValidateInputQuicktask.offsiteusername
        }
        return true
    }
}
