//
//  ObservableGlobalchangeConfigurations.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/06/2021.
//
// swiftlint:disable line_length

import Foundation
import Observation

enum GlobalchangeConfiguration: String, Codable {
    case localcatalog
    case remotecatalog
    case remoteuser
    case remoteserver
    case backupID
}

@Observable @MainActor
final class ObservableGlobalchangeConfigurations {
    var occurence_backupID: String = ""
    var replace_backupID: String = ""
    var occurence_localcatalog: String = ""
    var replace_localcatalog: String = ""
    var occurence_remotecatalog: String = ""
    var replace_remotecatalog: String = ""
    var occurence_remoteuser: String = ""
    var occurence_remoteserver: String = ""
    

    var showAlertforupdate: Bool = false

    var whatischanged: Set<GlobalchangeConfiguration> = []

    var globalchangedconfigurations: [SynchronizeConfiguration]?
    // Not changed snapshots, but if snapshots then merge with globalchangedconfigurations
    var notchangedsnapshotconfigurations: [SynchronizeConfiguration]?

    func resetform() {
        occurence_localcatalog = ""
        replace_localcatalog = ""
        occurence_remotecatalog = ""
        replace_remotecatalog = ""
        occurence_remoteuser = ""
        occurence_remoteserver = ""
        occurence_backupID = ""
        replace_backupID = ""
        whatischanged.removeAll()
    }

    func splitinput(input: String, original: String) -> String {
        guard input.isEmpty == false else { return original }
        let trimmed = input.replacingOccurrences(of: " ", with: "")
        let split = trimmed.split(separator: "$")
        guard split.count == 2 else { return original }
        return original.replacingOccurrences(of: String(split[0]), with: String(split[1]))
    }
    
    func updatestring(update: String, replace: String, original: String) -> String {
        guard update.isEmpty == false else { return original }
        guard replace.isEmpty == false else { return original }
        return original.replacingOccurrences(of: replace, with: update)
    }

    func updateglobalchangedconfigurations() {
        guard whatischanged.isEmpty == false else { return }

        for element in whatischanged {
            switch element {
            case .localcatalog:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.localCatalog
                    if occurence_localcatalog.contains("$") {
                        let trimmed = occurence_localcatalog.replacingOccurrences(of: " ", with: "")
                        let split = trimmed.split(separator: "$")
                        guard split.count == 2 else { return task }
                        let newstring = oldsstring.replacingOccurrences(of: split[0], with: split[1])
                        var newtask = task
                        newtask.localCatalog = newstring
                        return newtask
                    } else {
                        let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_localcatalog)
                        var newtask = task
                        newtask.localCatalog = newstring
                        return newtask
                    }
                }
            case .remotecatalog:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.offsiteCatalog
                    if occurence_remotecatalog.contains("$") {
                        let trimmed = occurence_remotecatalog.replacingOccurrences(of: " ", with: "")
                        let split = trimmed.split(separator: "$")
                        guard split.count == 2 else { return task }
                        let newstring = oldsstring.replacingOccurrences(of: split[0], with: split[1])
                        var newtask = task
                        newtask.offsiteCatalog = newstring
                        return newtask
                    } else {
                        let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remotecatalog)
                        var newtask = task
                        newtask.offsiteCatalog = newstring
                        return newtask
                    }
                }
            case .remoteuser:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.offsiteUsername
                    let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remoteuser)
                    var newtask = task
                    newtask.offsiteUsername = newstring
                    return newtask
                }
            case .remoteserver:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.offsiteServer
                    let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_remoteserver)
                    var newtask = task
                    newtask.offsiteServer = newstring
                    return newtask
                }
            case .backupID:
                globalchangedconfigurations = globalchangedconfigurations?.map { task in
                    let oldsstring = task.backupID
                    if occurence_backupID.contains("$") {
                        let trimmed = occurence_backupID.replacingOccurrences(of: " ", with: "")
                        let split = trimmed.split(separator: "$")
                        guard split.count == 2 else { return task }
                        let newstring = oldsstring.replacingOccurrences(of: split[0], with: split[1])
                        var newtask = task
                        newtask.backupID = newstring
                        return newtask
                    } else {
                        let newstring = oldsstring.replacingOccurrences(of: oldsstring, with: occurence_backupID)
                        var newtask = task
                        newtask.backupID = newstring
                        return newtask
                    }
                }
            }
        }
        resetform()
    }
}

// swiftlint:enable line_length
