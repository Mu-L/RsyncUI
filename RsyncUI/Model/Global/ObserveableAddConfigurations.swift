//
//  ObserveableReferenceAddConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//
// swiftlint:disable function_body_length type_body_length

import Combine

import Foundation

enum CannotUpdateSnaphotsError: LocalizedError {
    case cannotupdate

    var errorDescription: String? {
        switch self {
        case .cannotupdate:
            return "Only synchronize ID can be changed on a Snapshot task"
        }
    }
}

final class ObserveableAddConfigurations: ObservableObject {
    @Published var localcatalog: String = ""
    @Published var remotecatalog: String = ""
    @Published var donotaddtrailingslash: Bool = false
    @Published var remoteuser: String = ""
    @Published var remoteserver: String = ""
    @Published var backupID: String = ""
    // @Published var selectedconfig: Configuration?
    @Published var selectedrsynccommand = TypeofTask.synchronize

    @Published var newprofile: String = ""
    @Published var selectedprofile: String?
    @Published var deletedefaultprofile: Bool = false

    @Published var deleted: Bool = false
    @Published var added: Bool = false
    @Published var updated: Bool = false
    @Published var created: Bool = false
    @Published var reload: Bool = false
    @Published var confirmdeleteselectedprofile: Bool = false
    @Published var showAlertfordelete: Bool = false

    // For update post and pretasks
    var enablepre: Bool = false
    var enablepost: Bool = false
    var pretask: String = ""
    var posttask: String = ""
    var haltshelltasksonerror: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()
    // Set true if remote storage is a local attached Volume
    var remotestorageislocal: Bool = false

    var selectedconfig: Configuration?

    init() {
        $donotaddtrailingslash
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $localcatalog
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $remotecatalog
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { [unowned self] _ in
                remotestorageislocal = verifyremotestorageislocal()
            }.store(in: &subscriptions)
        $remoteuser
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $remoteserver
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $backupID
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $selectedrsynccommand
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $newprofile
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $selectedprofile
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $deletedefaultprofile
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $confirmdeleteselectedprofile
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
        $showAlertfordelete
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .receive(on: DispatchQueue.main).sink { _ in
            }.store(in: &subscriptions)
    }

    func addconfig(_ profile: String?, _ configurations: [Configuration]?) {
        let getdata = AppendTask(selectedrsynccommand.rawValue,
                                 localcatalog,
                                 remotecatalog,
                                 donotaddtrailingslash,
                                 remoteuser,
                                 remoteserver,
                                 backupID,
                                 // add post and pretask in it own view, set nil here
                                 nil,
                                 nil,
                                 nil,
                                 nil,
                                 nil)
        // If newconfig is verified add it
        if let newconfig = VerifyConfiguration().verify(getdata) {
            let updateconfigurations =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            if updateconfigurations.addconfiguration(newconfig) == true {
                reload = true
                added = true
                resetform()
            }
        }
    }

    func updateconfig(_ profile: String?, _ configurations: [Configuration]?) {
        updatepreandpost()
        let updateddata = AppendTask(selectedrsynccommand.rawValue,
                                     localcatalog,
                                     remotecatalog,
                                     donotaddtrailingslash,
                                     remoteuser,
                                     remoteserver,
                                     backupID,
                                     // add post and pretask in it own view,
                                     // but if update save pre and post task
                                     enablepre,
                                     pretask,
                                     enablepost,
                                     posttask,
                                     haltshelltasksonerror,
                                     selectedconfig?.hiddenID ?? -1)
        if let updatedconfig = VerifyConfiguration().verify(updateddata) {
            let updateconfiguration =
                UpdateConfigurations(profile: profile,
                                     configurations: configurations)
            updateconfiguration.updateconfiguration(updatedconfig, false)
            reload = true
            updated = true
            resetform()
        }
    }

    func resetform() {
        localcatalog = ""
        remotecatalog = ""
        donotaddtrailingslash = false
        remoteuser = ""
        remoteserver = ""
        backupID = ""
        selectedconfig = nil
    }

    func createprofile() {
        guard newprofile.isEmpty == false else { return }
        let catalogprofile = CatalogProfile()
        catalogprofile.createprofilecatalog(profile: newprofile)
        selectedprofile = newprofile
        created = true
        newprofile = ""
    }

    func deleteprofile(_ profile: String?) {
        guard confirmdeleteselectedprofile == true else { return }
        if let profile = profile {
            guard profile != SharedReference.shared.defaultprofile else {
                deletedefaultprofile = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                    deletedefaultprofile = false
                }
                return
            }
            CatalogProfile().deleteprofilecatalog(profileName: profile)
            selectedprofile = nil
            deleted = true
        } else {
            deletedefaultprofile = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                deletedefaultprofile = false
            }
        }
    }

    func validateandupdate(_ profile: String?, _ configurations: [Configuration]?) {
        // Validate not a snapshot task
        do {
            let validated = try validatenotsnapshottask()
            if validated {
                updateconfig(profile, configurations)
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    func updateview(_ config: Configuration?) {
        selectedconfig = config
        if let config = selectedconfig {
            localcatalog = config.localCatalog
            remotecatalog = config.offsiteCatalog
            remoteuser = config.offsiteUsername
            remoteserver = config.offsiteServer
            backupID = config.backupID
        } else {
            selectedconfig = nil
            localcatalog = ""
            remotecatalog = ""
            remoteuser = ""
            remoteserver = ""
            backupID = ""
        }
    }

    private func validatenotsnapshottask() throws -> Bool {
        if let config = selectedconfig {
            if config.task == SharedReference.shared.snapshot {
                throw CannotUpdateSnaphotsError.cannotupdate
            } else {
                return true
            }
        }
        return false
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }

    func verifyremotestorageislocal() -> Bool {
        do {
            _ = try Folder(path: remotecatalog)
            return true
        } catch {
            return false
        }
    }

    private func updatepreandpost() {
        if let config = selectedconfig {
            // pre task
            pretask = config.pretask ?? ""
            if config.pretask != nil {
                if config.executepretask == 1 {
                    enablepre = true
                } else {
                    enablepre = false
                }
            } else {
                enablepre = false
            }

            // post task
            posttask = config.posttask ?? ""
            if config.posttask != nil {
                if config.executeposttask == 1 {
                    enablepost = true
                } else {
                    enablepost = false
                }
            } else {
                enablepost = false
            }

            if config.posttask != nil {
                if config.haltshelltasksonerror == 1 {
                    haltshelltasksonerror = true
                } else {
                    haltshelltasksonerror = false
                }
            } else {
                haltshelltasksonerror = false
            }
        }
    }
}
