//
//  ExecuteOneTask.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation

final class ExecuteOneTask {
    var arguments: [String]?
    var termination: ([String]?, Int?) -> Void
    var filehandler: (Int) -> Void
    var config: Configuration?

    func startexecution() {
        if let arguments = arguments {
            let process = RsyncProcess(arguments: arguments,
                                       config: config,
                                       processtermination: termination,
                                       filehandler: filehandler)
            process.executeProcess()
        }
    }

    init(hiddenID: Int,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         termination: @escaping ([String]?, Int?) -> Void,
         filehandler: @escaping (Int) -> Void)
    {
        self.termination = termination
        self.filehandler = filehandler
        config = configurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)
        if let config = config {
            arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .arg)
        }
    }

    deinit {
        // print("deinit ExecuteOneTask")
    }
}
