//
//  ExecuteTasksNOEstimation.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//

import Foundation
import OSLog

@MainActor
final class ExecuteTasksNOEstimation {
    var structprofile: String?
    var localconfigurations: [SynchronizeConfiguration]
    var stackoftasktobeestimated: [Int]?
    weak var localexecutenoestimationprogressdetails: ExecuteNoEstimationProgressDetails?
    // Collect loggdata for later save to permanent storage
    // (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()
    // Update configigurations
    var localupdateconfigurations: ([SynchronizeConfiguration]) -> Void

    func getconfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    func startexecution() {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            let update = Logging(profile: structprofile,
                                 configurations: localconfigurations)
            let updateconfigurations = update.setCurrentDateonConfiguration(configrecords: configrecords)
            // Send date stamped configurations back to caller
            localupdateconfigurations(updateconfigurations)
            // Update logrecords
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            localexecutenoestimationprogressdetails?.executealltasksnoestiamtioncomplete()
            Logger.process.info("class ExecuteTasks: execution is completed")
            return
        }
        if let localhiddenID = stackoftasktobeestimated?.removeLast() {
            if let config = getconfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: false,
                                                                                             forDisplay: false)
                {
                    guard arguments.count > 0 else { return }
                    let process = ProcessRsync(arguments: arguments,
                                               config: config,
                                               processtermination: processtermination)
                    process.executeProcess()
                }
            }
        }
    }

    init(profile: String?,
         rsyncuiconfigurations: [SynchronizeConfiguration],
         executenoestimationprogressdetails: ExecuteNoEstimationProgressDetails?,
         selecteduuids: Set<UUID>,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
    {
        structprofile = profile
        localconfigurations = rsyncuiconfigurations
        localexecutenoestimationprogressdetails = executenoestimationprogressdetails
        localupdateconfigurations = updateconfigurations
        // Estimate selected configurations
        if selecteduuids.count > 0 {
            let configurations = localconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }
            stackoftasktobeestimated = configurations.map(\.hiddenID)
        } else {
            let configurations = localconfigurations.filter { $0.task != SharedReference.shared.halted }
            stackoftasktobeestimated = configurations.map(\.hiddenID)
        }
    }
}

extension ExecuteTasksNOEstimation {
    func processtermination(stringoutputfromrsync: [String]?, hiddenID: Int?) {
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        
        var suboutput: [String]?
        
        configrecords.append((hiddenID ?? -1, Date().en_us_string_from_date()))
        if let config = getconfig(hiddenID ?? -1) {
            
            if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
                suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            } else {
                suboutput = stringoutputfromrsync
            }
            
            let record = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                           config: config)
            if let stats = record.stats {
                schedulerecords.append((hiddenID ?? -1, stats))
                localexecutenoestimationprogressdetails?.appendrecordexecutedlist(record)
                localexecutenoestimationprogressdetails?.appenduuidwithdatatosynchronize(config.id)
                startexecution()
            }
        }
    }
}
