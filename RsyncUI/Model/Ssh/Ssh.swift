//
//  ssh.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation

enum SshError: LocalizedError {
    case notvalidpath
    case sshkeys
    case noslash

    var errorDescription: String? {
        switch self {
        case .notvalidpath:
            return NSLocalizedString("SSH keypath is not valid", comment: "ssh error") + "..."
        case .sshkeys:
            return NSLocalizedString("SSH RSA keys exist", comment: "ssh error") + "..."
        case .noslash:
            return NSLocalizedString("SSH keypath must be like ~/.ssh_keypath/identityfile", comment: "ssh error") + "..."
        }
    }
}

class Ssh: Catalogsandfiles {
    // Process termination and filehandler closures
    var commandCopyPasteTerminal: String?
    var rsaStringPath: String?
    // Arrays listing all key files
    var keyFileStrings: [String]?
    var argumentsssh: ArgumentsSsh?
    var command: String?
    var arguments: [String]?
    var outputprocess: OutputProcess?
    var data: [String]?

    // Create rsa keypair
    func createPublicPrivateRSAKeyPair() {
        do {
            let ok = try islocalpublicrsakeypresent()
            if ok == false {
                // Create keys
                argumentsssh = ArgumentsSsh(remote: nil, sshkeypathandidentityfile: (fullroot ?? "") +
                    "/" + (identityfile ?? ""))
                arguments = argumentsssh?.argumentscreatekey()
                command = argumentsssh?.getCommand()
                // executeSshCommand()
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    // Check if rsa pub key exists
    func islocalpublicrsakeypresent() throws -> Bool {
        guard keyFileStrings != nil else { return false }
        guard keyFileStrings?.filter({ $0.contains(self.identityfile ?? "") }).count ?? 0 > 0 else { return false }
        guard keyFileStrings?.filter({ $0.contains((self.identityfile ?? "") + ".pub") }).count ?? 0 > 0 else {
            throw SshError.sshkeys
        }
        rsaStringPath = keyFileStrings?.filter { $0.contains((self.identityfile ?? "") + ".pub") }[0]
        guard rsaStringPath?.count ?? 0 > 0 else { return false }
        throw SshError.sshkeys
    }

    func validatepublickeypresent() -> Bool {
        guard keyFileStrings != nil else { return false }
        guard keyFileStrings?.filter({ $0.contains(self.identityfile ?? "") }).count ?? 0 > 0 else { return false }
        guard keyFileStrings?.filter({ $0.contains((self.identityfile ?? "") + ".pub") }).count ?? 0 > 0 else {
            return true
        }
        rsaStringPath = keyFileStrings?.filter { $0.contains((self.identityfile ?? "") + ".pub") }[0]
        guard rsaStringPath?.count ?? 0 > 0 else { return false }
        return true
    }

    // Secure copy of public key from local to remote catalog
    func copylocalpubrsakeyfile(remote: UniqueserversandLogins?) -> String {
        let argumentsssh = ArgumentsSsh(remote: remote, sshkeypathandidentityfile: (fullroot ?? "") +
            "/" + (identityfile ?? ""))
        return argumentsssh.argumentssshcopyid() ?? ""
    }

    // Check for remote pub keys
    func verifyremotekey(remote: UniqueserversandLogins?) -> String {
        let argumentsssh = ArgumentsSsh(remote: remote, sshkeypathandidentityfile: (fullroot ?? "") +
            "/" + (identityfile ?? ""))
        return argumentsssh.argumentscheckremotepubkey() ?? ""
    }

    // Execute command
    func executeSshCommand() {
        guard arguments != nil else { return }
        outputprocess = OutputProcess()
        let process = OtherProcessCmdClosure(command: command,
                                             arguments: arguments,
                                             processtermination: processtermination,
                                             filehandler: filehandler)
        process.executeProcess(outputprocess: outputprocess)
    }

    init() {
        super.init(profileorsshrootpath: .sshroot)
        keyFileStrings = getfilesasstringnames()
    }
}

extension Ssh {
    func processtermination() {}

    func filehandler() {
        data = outputprocess?.getOutput()
    }
}
