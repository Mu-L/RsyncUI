//
//  EstimationOnetaskAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2022.
//

import Foundation

final class EstimationOnetaskAsync {
    private var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    private var estimationonetask: EstimationOnetaskAsync?
    private var localhiddenID: Int = 0

    weak var stateDelegate: EstimationState?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    var arguments: [String]?
    var config: Configuration?
    var hiddenID: Int?

    @MainActor
    func startestimation() async {
        if let arguments = arguments {
            let process = RsyncProcessAsync(arguments: arguments,
                                            config: config,
                                            processtermination: processtermination)
            await process.executeProcess()
        }
    }

    init(configurationsSwiftUI: ConfigurationsSwiftUI?,
         estimationstateDelegate: EstimationState?,
         updateinprogresscount: UpdateEstimationCount?,
         hiddenID: Int)
    {
        localconfigurationsSwiftUI = configurationsSwiftUI
        stateDelegate = estimationstateDelegate
        updateestimationcountDelegate = updateinprogresscount
        localhiddenID = hiddenID
        // local is true for getting info about local catalogs.
        // used when shwoing diff local files vs remote files
        arguments = configurationsSwiftUI?.arguments4rsync(hiddenID: localhiddenID, argtype: .argdryRun)
        config = configurationsSwiftUI?.getconfiguration(hiddenID: localhiddenID)
    }

    private func getconfig(hiddenID: Int?) -> Configuration? {
        if let hiddenID = hiddenID {
            if let configurations = localconfigurationsSwiftUI?.getallconfigurations()?.filter({ $0.hiddenID == hiddenID }) {
                guard configurations.count == 1 else { return nil }
                return configurations[0]
            }
        }
        return nil
    }

    deinit {
        // print("deinit EstimationOnetask")
    }
}

extension EstimationOnetaskAsync {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: getconfig(hiddenID: hiddenID))
        updateestimationcountDelegate?.appendrecord(record: record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = getconfig(hiddenID: hiddenID) {
                updateestimationcountDelegate?.appenduuid(id: config.id)
            }
        }
    }
}
