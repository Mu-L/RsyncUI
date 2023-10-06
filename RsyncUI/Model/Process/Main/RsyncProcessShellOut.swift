//
//  RsyncProcessShellOut.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/10/2023.
//

import Combine
import Foundation

final class RsyncProcessShellOut {
    // Combine subscribers
    var subscriptons = Set<AnyCancellable>()
    // Process termination and filehandler closures
    var processtermination: ([String]?, Int?) -> Void
    var filehandler: (Int) -> Void
    // Verify network connection
    var config: Configuration?
    var monitor: NetworkMonitor?
    // Arguments to command
    var arguments: [String]?
    // Output
    var outputprocess: OutputfromProcess?

    func executemonitornetworkconnection() {
        guard config?.offsiteServer.isEmpty == false else { return }
        guard SharedReference.shared.monitornetworkconnection == true else { return }
        monitor = NetworkMonitor()
        monitor?.netStatusChangeHandler = { [unowned self] in
            do {
                try statusDidChange()
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    // Throws error
    func statusDidChange() throws {
        if monitor?.monitor?.currentPath.status != .satisfied {
            _ = InterruptProcess()
            throw Networkerror.networkdropped
        }
    }

    private func localfilehandler() -> Int {
        return outputprocess?.getOutput()?.count ?? 0
    }

    func executeProcess() {
        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        // Process
        let task = Process()
        // Getting version of rsync
        task.launchPath = GetfullpathforRsync().rsyncpath
        task.arguments = arguments
        // If there are any Environmentvariables like
        // SSH_AUTH_SOCK": "/Users/user/.gnupg/S.gpg-agent.ssh"
        if let environment = Environment() {
            task.environment = environment.environment
        }
        // Pipe for reading output from Process
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        // Combine, subscribe to NSNotification.Name.NSFileHandleDataAvailable
        NotificationCenter.default.publisher(
            for: NSNotification.Name.NSFileHandleDataAvailable)
            .sink { [self] _ in
                let data = outHandle.availableData
                if data.count > 0 {
                    if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                        self.outputprocess?.addlinefromoutput(str: str as String)
                        // Send message about files
                        self.filehandler(self.outputprocess?.getOutput()?.count ?? 0)
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                }
            }.store(in: &subscriptons)
        // Combine, subscribe to Process.didTerminateNotification
        NotificationCenter.default.publisher(
            for: Process.didTerminateNotification)
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [self] _ in
                self.processtermination(self.outputprocess?.getOutput(), self.config?.hiddenID)
                // Logg to file
                _ = Logfile(TrimTwo(outputprocess?.getOutput() ?? []).trimmeddata, error: false)
                // Release Combine subscribers
                subscriptons.removeAll()
                // Execute posttask
                do {
                    if self.config?.executeposttask == 1,
                       self.config?.posttask?.isEmpty == false
                    {
                        try self.executeposttask()
                    }
                } catch {
                    return
                }
            }.store(in: &subscriptons)

        // Execute pretask
        do {
            if config?.executepretask == 1,
               config?.pretask?.isEmpty == false
            {
                try executepretask()
            }
        } catch {
            return
        }

        SharedReference.shared.process = task
        do {
            try task.run()
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    // Terminate Process, used when user Aborts task.
    func abortProcess() {
        _ = InterruptProcess()
    }

    init(arguments: [String]?,
         config: Configuration?,
         processtermination: @escaping ([String]?, Int?) -> Void,
         filehandler: @escaping (Int) -> Void)
    {
        self.arguments = arguments
        self.processtermination = processtermination
        self.filehandler = filehandler
        self.config = config
        outputprocess = OutputfromProcess()
        executemonitornetworkconnection()
    }

    deinit {
        self.monitor?.stopMonitoring()
        self.monitor = nil
        SharedReference.shared.process = nil
        // print("deinit RsyncProcess")
    }
}

extension RsyncProcessShellOut {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alerterror(error: error)
    }

    func executepretask() throws {
        if let pretask = config?.pretask {
            do {
                try shellOut(to: pretask)
            } catch let e {
                let error = e as? ShellOutError
                let outputprocess = OutputfromProcess()
                outputprocess.addlinefromoutput(str: "ShellOut: pretask fault, aborting")
                outputprocess.addlinefromoutput(str: error?.message ?? "")
                _ = Logfile(TrimTwo(outputprocess.getOutput() ?? []).trimmeddata, error: true)
            }
        }
    }

    func executeposttask() throws {
        if let posttask = config?.posttask {
            do {
                try shellOut(to: posttask)
            } catch let e {
                let error = e as? ShellOutError
                let outputprocess = OutputfromProcess()
                outputprocess.addlinefromoutput(str: "ShellOut: posttask fault, aborting")
                outputprocess.addlinefromoutput(str: error?.message ?? "")
                _ = Logfile(TrimTwo(outputprocess.getOutput() ?? []).trimmeddata, error: true)
            }
        }
    }
}
