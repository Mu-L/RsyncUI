//
//  SidebarMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2023.
//

import OSLog
import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, tasks, rsync_parameters, snapshots, log_listings, restore, profiles, verify_remote
    var id: String { rawValue }
}

// The sidebar is context sensitive, it is computed everytime a new profile is loaded

struct MenuItem: Identifiable, Hashable {
    var menuitem: Sidebaritems
    let id = UUID()
}

struct SidebarMainView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Bindable var errorhandling: AlertError

    @State private var estimateprogressdetails = EstimateProgressDetails()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedview: Sidebaritems = .synchronize
    // Navigation rsyncparameters
    @State var rsyncnavigation: [ParametersTasks] = []
    // Navigation executetasks
    @State var executetasknavigation: [Tasks] = []
    // Navigation addtasks and verify
    // Needed here because if not empty sidebar is disabled
    @State private var addtasknavigation: [AddTasks] = []
    @State var verifynavigationispresented = false
    // Check if new version
    @State private var newversion = CheckfornewversionofRsyncUI()
    // URL code
    @State var queryitem: URLQueryItem?
    // Bindings in TaskView triggered when Toolbar Icons, in TaskView, are pressed
    // Toolbar Icons with yellow icons
    @State var urlcommandestimateandsynchronize = false
    @State var urlcommandverify = false
    // Toggle sidebar
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    // .doubleColumn
    // .detailOnly
    @State private var mountingvolumenow: Bool = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Picker("", selection: $selectedprofile) {
                ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                    Text(profile.profilename)
                        .tag(profile.profilename)
                }
            }
            .frame(width: 180)
            .padding([.bottom, .top, .trailing], 7)
            .disabled(disablesidebarmeny)

            Divider()

            List(menuitems, selection: $selectedview) { item in
                NavigationLink(value: item.menuitem) {
                    SidebarRow(sidebaritem: item.menuitem)
                }

                if item.menuitem == .tasks ||
                    item.menuitem == .snapshots ||
                    item.menuitem == .log_listings ||
                    item.menuitem == .restore
                { Divider() }
            }
            .listStyle(.sidebar)
            .disabled(disablesidebarmeny)

            if newversion.notifynewversion {
                MessageView(mytext: "Update available", size: .caption2)
                    .padding([.bottom], -30)
            }

            if mountingvolumenow {
                MessageView(mytext: "Mounting volume\nplease wait", size: .caption2)
                    .padding([.bottom], -30)
                    .onAppear {
                        Task {
                            try await Task.sleep(seconds: 3)
                            mountingvolumenow = false
                        }
                    }
            }

            MessageView(mytext: SharedReference.shared.rsyncversionshort ?? "", size: .caption2)

        } detail: {
            selectView(selectedview)
        }
        .alert(isPresented: errorhandling.presentalert, content: {
            if let error = errorhandling.activeError {
                Alert(localizedError: error)
            } else {
                Alert(title: Text("No error"))
            }
        })
        .onAppear {
            Task {
                newversion.notifynewversion = await Getversionofrsync().getversionsofrsyncui()
                SharedReference.shared.newversion = newversion.notifynewversion
                if SharedReference.shared.sidebarishidden {
                    columnVisibility = .detailOnly
                }
                // Only addObserver if there are more than the default profile
                if SharedReference.shared.observemountedvolumes, rsyncUIdata.validprofiles.count > 1 {
                    // Observer for mounting volumes
                    observerdidMountNotification()
                }
            }
        }
        .onOpenURL { incomingURL in
            // URL code
            // Deep link triggered RsyncUI from outside
            handleURLsidebarmainView(incomingURL, true)
        }
        .onChange(of: urlcommandestimateandsynchronize) {
            // URL code
            // Binding to listen for initiating deep link execute estimate and synchronize from
            // toolbar in TasksView
            let valueprofile = rsyncUIdata.profile ?? ""
            if let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: valueprofile) {
                handleURLsidebarmainView(url, false)
            }
        }
        .onChange(of: urlcommandverify) {
            // URL code
            // Binding to listen for initiating deep link execute estimate and synchronize from
            // toolbar in TasksView
            let valueprofile = rsyncUIdata.profile ?? ""
            var valueid = ""
            if let configurations = rsyncUIdata.configurations {
                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                    valueid = configurations[index].backupID
                    if let url = DeeplinkURL().createURLloadandverify(valueprofile: valueprofile,
                                                                      valueid: valueid)
                    {
                        handleURLsidebarmainView(url, false)
                    }
                }
            }
        }
        .onChange(of: rsyncUIdata.readdatafromstorecompleted) {
            Logger.process.info("SidebarMainView: READDATAFROMSTORECOMPLETED: \(rsyncUIdata.readdatafromstorecompleted)")
        }
        .onChange(of: selectedprofile) {
            selecteduuids.removeAll()
        }
    }

    @MainActor @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            AddTaskView(rsyncUIdata: rsyncUIdata,
                        selectedprofile: $selectedprofile, addtasknavigation: $addtasknavigation)
        case .log_listings:
            LogsbyConfigurationView(rsyncUIdata: rsyncUIdata)
        case .rsync_parameters:
            RsyncParametersView(rsyncUIdata: rsyncUIdata, rsyncnavigation: $rsyncnavigation)
        case .restore:
            NavigationStack {
                RestoreTableView(profile: $rsyncUIdata.profile,
                                 configurations: rsyncUIdata.configurations ?? [])
            }
        case .snapshots:
            SnapshotsView(rsyncUIdata: rsyncUIdata)
        case .synchronize:
            SidebarTasksView(rsyncUIdata: rsyncUIdata,
                             selectedprofile: $selectedprofile,
                             selecteduuids: $selecteduuids,
                             estimateprogressdetails: estimateprogressdetails,
                             executetasknavigation: $executetasknavigation,
                             queryitem: $queryitem,
                             urlcommandestimateandsynchronize: $urlcommandestimateandsynchronize,
                             urlcommandverify: $urlcommandverify,
                             columnVisibility: $columnVisibility)
        case .profiles:
            ProfileView(rsyncUIdata: rsyncUIdata, selectedprofile: $selectedprofile)
        case .verify_remote:
            NavigationStack {
                VerifyRemote(rsyncUIdata: rsyncUIdata,
                             verifynavigationispresented: $verifynavigationispresented,
                             queryitem: $queryitem)
            }
        }
    }

    var disablesidebarmeny: Bool {
        rsyncnavigation.isEmpty == false ||
            executetasknavigation.isEmpty == false ||
            addtasknavigation.isEmpty == false ||
            verifynavigationispresented == true ||
            SharedReference.shared.process != nil
    }

    // The Sidebar meny is context sensitive. There are three Sidebar meny options
    // which are context sensitive:
    // - Snapshots
    // - Verify remote
    // - Restore
    var menuitems: [MenuItem] {
        Sidebaritems.allCases.compactMap { item in
            // Return nil if there is one or more snapshot tasks
            // Do not show the Snapshot sidebar meny
            if rsyncUIdata.oneormoretasksissnapshot == false,
               item == .snapshots { return nil }

            // Return nil if there is one or more remote tasks
            // and only remote task is snapshot
            // Do not show the Verify remote sidebar meny
            if rsyncUIdata.oneormoretasksissnapshot == true,
               rsyncUIdata.oneormoresynchronizetasksisremote == false,
               item == .verify_remote { return nil }

            // Return nil if there is no remote tasks, only local attached discs
            // Do not show the Verify remote sidebar meny
            if rsyncUIdata.oneormoresynchronizetasksisremote == false,
               item == .verify_remote { return nil }

            // Return nil if there is no remote tasks, only local attached discs
            // Do not show the Restore remote sidebar meny
            if rsyncUIdata.oneormoresynchronizetasksisremote == false,
               rsyncUIdata.oneormoresnapshottasksisremote == false,
               item == .restore { return nil }

            return MenuItem(menuitem: item)
        }
    }
}

extension SidebarMainView {
    // URL code
    private func handleURLsidebarmainView(_ url: URL, _ waitasecond: Bool) {
        let deeplinkurl = DeeplinkURL()
        // Verify URL action is valid
        guard deeplinkurl.validatenoaction(queryitem) else { return }
        // Verify no other process is running
        guard SharedReference.shared.process == nil else { return }
        // Also veriy that no other query item is processed
        guard queryitem == nil else { return }

        switch deeplinkurl.handleURL(url)?.host {
        case .quicktask:
            Logger.process.info("handleURLsidebarmainView: URL Quicktask - \(url)")
            selectedview = .synchronize
            executetasknavigation.append(Tasks(task: .quick_synchronize))
        case .loadprofile:
            Logger.process.info("handleURLsidebarmainView: URL Loadprofile - \(url)")
            if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 1 {
                let profile = queryitems[0].value ?? ""
                if deeplinkurl.validateprofile(profile, rsyncUIdata.validprofiles) {
                    selectedprofile = profile
                }
            } else {
                return
            }
        case .loadprofileandestimate:
            Logger.process.info("handleURLsidebarmainView: URL Loadprofile and Estimate - \(url)")
            if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 1 {
                let profile = queryitems[0].value ?? ""

                if profile == "default" {
                    selectedprofile = SharedReference.shared.defaultprofile
                    selectedview = .synchronize
                    Task {
                        if waitasecond {
                            // If loaded from incoming URL, just wait a second to
                            // let profile load before comence action
                            try await Task.sleep(seconds: 1)
                        }
                        guard rsyncUIdata.readdatafromstorecompleted else { return }
                        guard rsyncUIdata.configurations?.count ?? 0 > 0 else { return }
                        // Observe queryitem
                        queryitem = queryitems[0]
                    }
                } else {
                    if deeplinkurl.validateprofile(profile, rsyncUIdata.validprofiles) {
                        selectedprofile = profile
                        selectedview = .synchronize
                        Task {
                            if waitasecond {
                                // If loaded from incoming URL, just wait a second to
                                // let profile load before comence action
                                try await Task.sleep(seconds: 1)
                            }
                            guard rsyncUIdata.readdatafromstorecompleted else { return }
                            guard rsyncUIdata.configurations?.count ?? 0 > 0 else { return }
                            // Observe queryitem
                            queryitem = queryitems[0]
                        }
                    }
                }

            } else {
                return
            }
        case .loadprofileandverify:
            Logger.process.info("handleURLsidebarmainView: URL Loadprofile and Verify - \(url)")

            if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 2 {
                let profile = queryitems[0].value ?? ""

                if profile == "default" {
                    selectedprofile = SharedReference.shared.defaultprofile
                    selectedview = .verify_remote
                    Task {
                        if waitasecond {
                            // If loaded from incoming URL, just wait a second to
                            // let profile load before comence action
                            try await Task.sleep(seconds: 1)
                        }
                        guard rsyncUIdata.readdatafromstorecompleted else { return }
                        guard rsyncUIdata.configurations?.count ?? 0 > 0 else { return }
                        // Observe queryitem
                        queryitem = queryitems[1]
                    }
                } else {
                    if deeplinkurl.validateprofile(profile, rsyncUIdata.validprofiles) {
                        selectedprofile = profile
                        selectedview = .verify_remote
                        Task {
                            if waitasecond {
                                // If loaded from incoming URL, just wait a second to
                                // let profile load before comence action
                                try await Task.sleep(seconds: 1)
                            }
                            guard rsyncUIdata.readdatafromstorecompleted else {
                                selectedview = .synchronize
                                return
                            }
                            guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                                selectedview = .synchronize
                                return
                            }
                            queryitem = queryitems[1]
                        }
                    }
                }
            } else {
                return
            }
        default:
            return
        }
    }

    func observerdidMountNotification() {
        Logger.process.info("SidebarMainView: observerdidMountNotification added")
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.didMountNotification,
                                       object: nil, queue: .main)
        { notification in
            if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                Logger.process.info("SidebarMainView: observerdidMountNotification \(volumeURL)")
                Task {
                    guard await tasksareinprogress() == false else { return }
                    await verifyandloadprofilemountedvolume(volumeURL)
                }
            }
        }
    }

    private func verifyandloadprofilemountedvolume(_ mountedvolume: URL) async {
        mountingvolumenow = true
        let allconfigurations = await ReadAllTasks().readalltasks(rsyncUIdata.validprofiles)
        let volume = mountedvolume.lastPathComponent
        let mappedallconfigurations = allconfigurations.compactMap { configuration in
            (configuration.offsiteServer.isEmpty == true &&
                configuration.offsiteCatalog.contains(volume) == true &&
                configuration.task != SharedReference.shared.halted) ? configuration : nil
        }
        let profile = mappedallconfigurations.compactMap(\.backupID)
        guard profile.count > 0 else {
            mountingvolumenow = false
            return
        }
        let uniqprofiles = Set(profile)
        selectedprofile = uniqprofiles.first
    }

    // Must check that no tasks are running
    private func tasksareinprogress() async -> Bool {
        guard SharedReference.shared.process == nil else {
            return true
        }
        guard estimateprogressdetails.estimatealltasksinprogress == false else {
            return true
        }
        guard executetasknavigation.isEmpty == true else {
            return true
        }
        return false
    }
}

struct SidebarRow: View {
    var sidebaritem: Sidebaritems

    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemimage(sidebaritem))
    }

    func systemimage(_ view: Sidebaritems) -> String {
        switch view {
        case .tasks:
            "text.badge.plus"
        case .log_listings:
            "text.alignleft"
        case .rsync_parameters:
            "command.circle.fill"
        case .restore:
            "arrowshape.turn.up.forward"
        case .snapshots:
            "text.badge.plus"
        case .synchronize:
            "arrowshape.turn.up.backward"
        case .profiles:
            "arrow.triangle.branch"
        case .verify_remote:
            "arrow.down.circle.fill"
        }
    }
}

/*
 extension SidebarMainView {
     // URL code
     private func handleURLsidebarmainView(_ url: URL) {
         Logger.process.info("handleURLsidebarmainView: URL request for: \(url)")

         let deeplinkurl = DeeplinkURL()
         // Verify URL action is valid
         guard deeplinkurl.validatenoaction(queryitem) else { return }
         // Verify no other process is running
         guard SharedReference.shared.process == nil else { return }
         // Also veriy that no other query item is processed
         guard queryitem == nil else { return }

         switch deeplinkurl.handleURL(url)?.host {
         case .quicktask:
             selectedview = .synchronize
             executetasknavigation.append(Tasks(task: .quick_synchronize))
         case .loadprofile:
             if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 1 {
                 let profile = queryitems[0].value ?? ""
                 if deeplinkurl.validateprofile(profile, rsyncUIdata.validprofiles) {
                     selectedprofile = profile
                 }
             } else {
                 return
             }
         case .loadprofileandestimate:
             if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 1 {
                 let profile = queryitems[0].value ?? ""

                 if profile == "default" {
                     Task {
                         await loadprofileforurllink(SharedReference.shared.defaultprofile)
                         guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                             selectedview = .synchronize
                             return
                         }
                         selectedview = .synchronize
                         queryitem = queryitems[0]
                     }
                 } else {
                     Task {
                         await loadprofileforurllink(profile)
                         guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                             selectedview = .synchronize
                             return
                         }
                         selectedview = .synchronize
                         queryitem = queryitems[0]
                     }
                 }
             } else {
                 return
             }
         case .loadprofileandverify:
             if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 2 {
                 let profile = queryitems[0].value ?? ""

                 if profile == "default" {
                     Task {
                         await loadprofileforurllink(SharedReference.shared.defaultprofile)
                         guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                             selectedview = .synchronize
                             return
                         }
                         selectedview = .verify_remote
                         queryitem = queryitems[1]
                     }
                 } else {
                     if deeplinkurl.validateprofile(profile, rsyncUIdata.validprofiles) {
                         Task {
                             await loadprofileforurllink(profile)
                             guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                                 selectedview = .synchronize
                                 return
                             }
                             selectedview = .verify_remote
                             queryitem = queryitems[1]
                         }
                     }
                 }
             } else {
                 return
             }
         default:
             return
         }
     }


     // Must load profile for URL-link async to make sure profile is
     // loaded ahead of start requested action.
     func loadprofileforurllink(_ profile: String) async {
         Logger.process.info("SidebarMainView: loadprofileforurllink executed")
         if profile == "default" {
             rsyncUIdata.profile = SharedReference.shared.defaultprofile
             selectedprofile = SharedReference.shared.defaultprofile
         } else {
             rsyncUIdata.profile = profile
             selectedprofile = profile
         }
         rsyncUIdata.configurations = await ActorReadSynchronizeConfigurationJSON()
             .readjsonfilesynchronizeconfigurations(selectedprofile,
                                                    SharedReference.shared.monitornetworkconnection,
                                                    SharedReference.shared.sshport,
                                                    SharedReference.shared.fileconfigurationsjson)
     }
 }

 */
