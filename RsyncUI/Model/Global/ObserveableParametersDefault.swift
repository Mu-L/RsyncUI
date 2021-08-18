//
//  ObserveableParametersDefault.swift
//  ObserveableParametersDefault
//
//  Created by Thomas Evensen on 18/08/2021.
//

import Combine
import Foundation

final class ObserveableParametersDefault: ObservableObject {
    // Rsync parameters
    @Published var parameter8: String = ""
    @Published var parameter9: String = ""
    @Published var parameter10: String = ""
    @Published var parameter11: String = ""
    @Published var parameter12: String = ""
    @Published var parameter13: String = ""
    @Published var parameter14: String = ""
    // Selected configuration
    @Published var configuration: Configuration?
    // Local SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    @Published var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var sshkeypathandidentityfile: String = ""
    // Remove parameters
    @Published var removessh: Bool = false
    @Published var removecompress: Bool = false
    @Published var removedelete: Bool = false
    // Buttons
    @Published var suffixlinux: Bool = false
    @Published var suffixfreebsd: Bool = false
    @Published var backup: Bool = false
    @Published var daemon: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()
    // parameters for delete
    var parameter3: String?
    var parameter4: String?
    var parameter5: String?
    var rsyncdaemon: Int?

    // Value to check if input field is changed by user
    @Published var inputchangedbyuser: Bool = false

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter8
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter9
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter10
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter11
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter12
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter13
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter14
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $configuration
            .sink { [unowned self] config in
                if let config = config { setvalues(config) }
            }.store(in: &subscriptions)
        $sshkeypathandidentityfile
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] identityfile in
                sshkeypathandidentiyfile(identityfile)
            }.store(in: &subscriptions)
        $sshport
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] port in
                sshport(port)
            }.store(in: &subscriptions)
        $removessh
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] ssh in
                deletessh(ssh)
            }.store(in: &subscriptions)
        $removedelete
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] delete in
                deletedelete(delete)
            }.store(in: &subscriptions)
        $removecompress
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] compress in
                deletecompress(compress)
            }.store(in: &subscriptions)
        $suffixlinux
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                setsuffixlinux()
            }.store(in: &subscriptions)
        $suffixfreebsd
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                setsuffixfreebsd()
            }.store(in: &subscriptions)
        $daemon
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                // TODO: fix rsyncdaemon
                // setrsyncdaemon()
            }.store(in: &subscriptions)
        $backup
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                setbackup()
            }.store(in: &subscriptions)
    }
}

extension ObserveableParametersDefault {
    func setvalues(_ config: Configuration) {
        inputchangedbyuser = false
        parameter8 = config.parameter8 ?? ""
        parameter9 = config.parameter9 ?? ""
        parameter10 = config.parameter10 ?? ""
        parameter11 = config.parameter11 ?? ""
        parameter12 = config.parameter12 ?? ""
        parameter13 = config.parameter13 ?? ""
        parameter14 = config.parameter14 ?? ""
        if let configsshport = config.sshport {
            sshport = String(configsshport)
        } else {
            sshport = ""
        }
        sshkeypathandidentityfile = config.sshkeypathandidentityfile ?? ""
        parameter3 = config.parameter3
        parameter4 = config.parameter4
        parameter5 = config.parameter5
        // set delete toggles
        if (parameter3 ?? "").isEmpty { removecompress = true } else { removecompress = false }
        if (parameter4 ?? "").isEmpty { removedelete = true } else { removedelete = false }
        if (parameter5 ?? "").isEmpty { removessh = true } else { removessh = false }
        // Rsync daemon
        rsyncdaemon = config.rsyncdaemon
    }

    // parameter5 -e ssh
    private func deletessh(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter5 = nil
        } else {
            parameter5 = "-e"
        }
    }

    // parameter4 --delete
    private func deletedelete(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter4 = nil
        } else {
            parameter4 = "--delete"
        }
    }

    // parameter3 --compress
    private func deletecompress(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter3 = nil
        } else {
            parameter3 = "--compress"
        }
    }

    // SSH identityfile
    private func checksshkeypathbeforesaving(_ keypath: String) throws -> Bool {
        if keypath.first != "~" { throw SshError.noslash }
        let tempsshkeypath = keypath
        let sshkeypathandidentityfilesplit = tempsshkeypath.split(separator: "/")
        guard sshkeypathandidentityfilesplit.count > 2 else { throw SshError.noslash }
        guard sshkeypathandidentityfilesplit[1].count > 1 else { throw SshError.notvalidpath }
        guard sshkeypathandidentityfilesplit[2].count > 1 else { throw SshError.notvalidpath }
        return true
    }

    func sshkeypathandidentiyfile(_ keypath: String) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        // If keypath is empty set it to nil, e.g default value
        guard keypath.isEmpty == false else {
            configuration?.sshkeypathandidentityfile = nil
            return
        }
        do {
            let verified = try checksshkeypathbeforesaving(keypath)
            if verified {
                configuration?.sshkeypathandidentityfile = keypath
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    // SSH port number
    private func checksshport(_ port: String) throws -> Bool {
        guard port.isEmpty == false else { return false }
        if Int(port) != nil {
            return true
        } else {
            throw InputError.notvalidInt
        }
    }

    func sshport(_ port: String) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        // if port is empty set it to nil, e.g. default value
        guard port.isEmpty == false else {
            configuration?.sshport = nil
            return
        }
        do {
            let verified = try checksshport(port)
            if verified {
                configuration?.sshport = Int(port)
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    func setbackup() {
        guard inputchangedbyuser == true else { return }
        if let config = configuration {
            let localcatalog = config.localCatalog
            let localcatalogparts = (localcatalog as AnyObject).components(separatedBy: "/")
            if parameter12.isEmpty == false {
                parameter12 = ""
            } else {
                parameter12 = RsyncArguments().backupstrings[0]
            }
            guard localcatalogparts.count > 2 else { return }
            if config.offsiteCatalog.contains("~") {
                if parameter13.isEmpty == false {
                    parameter13 = ""
                } else {
                    parameter13 = "~/backup" + "_" + localcatalogparts[localcatalogparts.count - 2]
                }
            } else {
                if parameter13.isEmpty == false {
                    parameter13 = ""
                } else {
                    parameter13 = "../backup" + "_" + localcatalogparts[localcatalogparts.count - 2]
                }
            }
        }
    }

    func setsuffixlinux() {
        guard inputchangedbyuser == true else { return }
        guard configuration != nil else { return }
        if parameter14.isEmpty == false {
            parameter14 = ""
        } else {
            parameter14 = RsyncArguments().suffixstringlinux
        }
    }

    func setsuffixfreebsd() {
        guard inputchangedbyuser == true else { return }
        guard configuration != nil else { return }
        if parameter14.isEmpty == false {
            parameter14 = ""
        } else {
            parameter14 = RsyncArguments().suffixstringfreebsd
        }
    }

    func setrsyncdaemon() {
        guard inputchangedbyuser == true else { return }
        guard configuration != nil else { return }
        if daemon {
            rsyncdaemon = 1
            parameter5 = ""
        } else {
            rsyncdaemon = nil
            parameter5 = "-e"
        }
    }

    // Return the updated configuration
    func updatersyncparameters() -> Configuration? {
        if var configuration = configuration {
            if parameter8.isEmpty { configuration.parameter8 = nil } else { configuration.parameter8 = parameter8 }
            if parameter9.isEmpty { configuration.parameter9 = nil } else { configuration.parameter9 = parameter9 }
            if parameter10.isEmpty { configuration.parameter10 = nil } else { configuration.parameter10 = parameter10 }
            if parameter11.isEmpty { configuration.parameter11 = nil } else { configuration.parameter11 = parameter11 }
            if parameter12.isEmpty { configuration.parameter12 = nil } else { configuration.parameter12 = parameter12 }
            if parameter13.isEmpty { configuration.parameter13 = nil } else { configuration.parameter13 = parameter13 }
            if parameter14.isEmpty { configuration.parameter14 = nil } else { configuration.parameter14 = parameter14 }
            if sshport.isEmpty {
                configuration.sshport = nil
            } else {
                configuration.sshport = Int(sshport)
            }
            if sshkeypathandidentityfile.isEmpty {
                configuration.sshkeypathandidentityfile = nil
            } else {
                configuration.sshkeypathandidentityfile = sshkeypathandidentityfile
            }
            if parameter3 == nil { configuration.parameter3 = "" } else { configuration.parameter3 = parameter3 ?? "" }
            if parameter4 == nil { configuration.parameter4 = "" } else { configuration.parameter4 = parameter4 ?? "" }
            if parameter5 == nil { configuration.parameter5 = "" } else { configuration.parameter5 = parameter5 ?? "" }
            configuration.rsyncdaemon = rsyncdaemon
            return configuration
        }
        return nil
    }
}

extension ObserveableParametersDefault: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
