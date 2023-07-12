//
//  ObserveableReferenceAddConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//
// swiftlint: disable type_body_length function_body_length

import Foundation
import Observation

enum CannotUpdateSnaphotsError: LocalizedError {
    case cannotupdate

    var errorDescription: String? {
        switch self {
        case .cannotupdate:
            return "Only synchronize ID can be changed on a Snapshot task"
        }
    }
}

@Observable
final class ObservableAddConfigurations {
    var localcatalog: String = ""
    var remotecatalog: String = ""
    var donotaddtrailingslash: Bool = false
    var remoteuser: String = ""
    var remoteserver: String = ""
    var backupID: String = ""
    var selectedrsynccommand = TypeofTask.synchronize

    var newprofile: String = ""
    var selectedprofile: String?
    var deletedefaultprofile: Bool = false

    var deleted: Bool = false
    var added: Bool = false
    var created: Bool = false
    var reload: Bool = false
    var confirmdeleteselectedprofile: Bool = false
    var showAlertfordelete: Bool = false

    var assistlocalcatalog: String = ""
    var assistremoteuser: String = ""
    var assistremoteserver: String = ""

    // alert about error
    var error: Error = InputError.noerror
    var alerterror: Bool = false

    // For update post and pretasks
    var enablepre: Bool = false
    var enablepost: Bool = false
    var pretask: String = ""
    var posttask: String = ""
    var haltshelltasksonerror: Bool = false

    // Set true if remote storage is a local attached Volume
    var remotestorageislocal: Bool = false
    var selectedconfig: Configuration?
    var localhome: String {
        return NamesandPaths(.configurations).userHomeDirectoryPath ?? ""
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
            // updated = true
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
            error = e
            alerterror = true
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

    func assistfunclocalcatalog(_ localcatalog: String) {
        guard localcatalog.isEmpty == false else { return }
        remotecatalog = "/mounted_Volume/" + localcatalog
        self.localcatalog = localhome + "/" + localcatalog
    }

    func assistfuncremoteuser(_ remoteuser: String) {
        guard remoteuser.isEmpty == false else { return }
        self.remoteuser = remoteuser
    }

    func assistfuncremoteserver(_ remoteserver: String) {
        guard remoteserver.isEmpty == false else { return }
        self.remoteserver = remoteserver
    }
}

// swiftlint: enable type_body_length function_body_length
