//
//  ObserveableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//
// swiftlint:disable function_body_length

import Combine
import Foundation

class ObserveableParametersRsync: ObservableObject {
    // When property is changed set isDirty = true
    @Published var isDirty: Bool = false
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
    // If local public sshkeys are present
    @Published var inputchangedbyuser: Bool = false
    // Remove parameters
    @Published var removessh: Bool = false
    @Published var removecompress: Bool = false
    @Published var removedelete: Bool = false
    // Buttons
    @Published var suffixlinux: Bool = false
    @Published var suffixfreebsd: Bool = false
    @Published var backup: Bool = false
    @Published var rsyncdaemon: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()
    // parameters for delete
    var parameter3: String?
    var parameter4: String?
    var parameter5: String?
    var deleteparameterschanged: Bool = false

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter8
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter8 in
                validate(parameter8)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter9
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter9 in
                validate(parameter9)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter10
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter10 in
                validate(parameter10)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter11
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter11 in
                validate(parameter11)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter12
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter12 in
                validate(parameter12)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter13
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter13 in
                validate(parameter13)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter14
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter14 in
                validate(parameter14)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $configuration
            .sink { [unowned self] config in
                if let config = config { setvalues(config) }
            }.store(in: &subscriptions)
        $sshkeypathandidentityfile
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] identityfile in
                sshkeypathandidentiyfile(identityfile)
            }.store(in: &subscriptions)
        $sshport
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
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
            }.store(in: &subscriptions)
        $suffixfreebsd
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
            }.store(in: &subscriptions)
        $rsyncdaemon
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
            }.store(in: &subscriptions)
        $backup
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                setbackup()
            }.store(in: &subscriptions)
    }

    private func validate(_ parameter: String) {
        print(parameter)
    }

    // parameter5
    private func deletessh(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter5 = ""
        } else {
            parameter5 = "-e"
        }
        isDirty = true
        deleteparameterschanged = true
    }

    // parameter4
    private func deletedelete(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter4 = ""
        } else {
            parameter4 = "--delete"
        }
        isDirty = true
        deleteparameterschanged = true
    }

    // parameter3
    private func deletecompress(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter3 = ""
        } else {
            parameter3 = "--compress"
        }
        isDirty = true
        deleteparameterschanged = true
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

    private func setvalues(_ config: Configuration) {
        isDirty = false
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
    }

    func sshkeypathandidentiyfile(_ keypath: String) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        // If keypath is empty set it to nil, e.g default value
        guard keypath.isEmpty == false else {
            configuration?.sshkeypathandidentityfile = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshkeypathbeforesaving(keypath)
            if verified {
                configuration?.sshkeypathandidentityfile = keypath
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
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
            isDirty = true
            return
        }
        do {
            let verified = try checksshport(port)
            if verified {
                configuration?.sshport = Int(port)
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    func setbackup() {
        guard inputchangedbyuser == true else { return }
        if let config = configuration {
            switch backup {
            case true:
                let localcatalog = config.localCatalog
                let localcatalogParts = (localcatalog as AnyObject).components(separatedBy: "/")
                parameter12 = RsyncArguments().backupstrings[0]
                parameter13 = "../backup" + "_" + localcatalogParts[localcatalogParts.count - 2]
                parameter14 = ""

            case false:
                parameter12 = ""
                parameter13 = ""
                parameter14 = ""
            }
        }
        isDirty = true
    }
}

extension ObserveableParametersRsync: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum ParameterError: LocalizedError {
    case notvalid

    var errorDescription: String? {
        switch self {
        case .notvalid:
            return NSLocalizedString("Not a valid ", comment: "ssh error") + "..."
        }
    }
}

/*

 // Function for enabling backup of changed files in a backup catalog.
 // Parameters are appended to last two parameters (12 and 13).
 @IBAction func backup(_: NSButton) {
     if let index = self.index() {
         if let configurations: [Configuration] = self.configurations?.getConfigurations() {
             let param = ComboboxRsyncParameters(config: configurations[index])
             switch self.backupbutton.state {
             case .on:
                 self.initcombox(combobox: self.combo12, index: param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[0]).0)
                 self.param12.stringValue = param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[0]).1
                 let hiddenID = self.configurations?.gethiddenID(index: (self.index())!)
                 guard (hiddenID ?? -1) > -1 else { return }
                 let localcatalog = self.configurations?.getResourceConfiguration(hiddenID ?? -1, resource: .localCatalog)
                 let localcatalogParts = (localcatalog as AnyObject).components(separatedBy: "/")
                 self.initcombox(combobox: self.combo13, index: param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[1]).0)
                 self.param13.stringValue = "../backup" + "_" + localcatalogParts[localcatalogParts.count - 2]
             case .off:
                 self.initcombox(combobox: self.combo12, index: 0)
                 self.param12.stringValue = ""
                 self.initcombox(combobox: self.combo13, index: 0)
                 self.param13.stringValue = ""
                 self.initcombox(combobox: self.combo14, index: 0)
                 self.param14.stringValue = ""
             default: break
             }
         }
     }
 }

 // Function for enabling suffix date + time changed files.
 // Parameters are appended to last parameter (14).
 @IBOutlet var suffixButton: NSButton!
 @IBAction func suffix(_: NSButton) {
     if let index = self.index() {
         self.suffixButton2.state = .off
         if let configurations: [Configuration] = self.configurations?.getConfigurations() {
             let param = ComboboxRsyncParameters(config: configurations[index])
             switch self.suffixButton.state {
             case .on:
                 let suffix = SuffixstringsRsyncParameters().suffixstringfreebsd
                 self.initcombox(combobox: self.combo14, index: param.indexandvaluersyncparameter(suffix).0)
                 self.param14.stringValue = param.indexandvaluersyncparameter(suffix).1
             case .off:
                 self.initcombox(combobox: self.combo14, index: 0)
                 self.param14.stringValue = ""
             default:
                 break
             }
         }
     }
 }

 @IBOutlet var suffixButton2: NSButton!
 @IBAction func suffix2(_: NSButton) {
     if let index = self.index() {
         if let configurations: [Configuration] = self.configurations?.getConfigurations() {
             let param = ComboboxRsyncParameters(config: configurations[index])
             self.suffixButton.state = .off
             switch self.suffixButton2.state {
             case .on:
                 let suffix = SuffixstringsRsyncParameters().suffixstringlinux
                 self.initcombox(combobox: self.combo14, index: param.indexandvaluersyncparameter(suffix).0)
                 self.param14.stringValue = param.indexandvaluersyncparameter(suffix).1
             case .off:
                 self.initcombox(combobox: self.combo14, index: 0)
                 self.param14.stringValue = ""
             default:
                 break
             }
         }
     }
 }

 */
