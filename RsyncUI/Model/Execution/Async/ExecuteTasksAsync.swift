//
//  ExecuteTasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//
// swiftlint:disable line_length

import Foundation
import OSLog

final class ExecuteTasksAsync {
    var structprofile: String?
    var localconfigurations: [SynchronizeConfiguration]
    var stackoftasktobeestimated: [Int]?
    weak var localexecuteasyncnoestimation: ExecuteAsyncNoEstimation?
    // Collect loggdata for later save to permanent storage
    // (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()
    // Update configigurations
    var localupdateconfigurations: ([SynchronizeConfiguration]) -> Void
    // ValidHiddenIDs
    var validhiddenIDs = Set<Int>()

    func getconfig(_ hiddenID: Int, _ configurations: [SynchronizeConfiguration]) -> SynchronizeConfiguration? {
        if let index = configurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return configurations[index]
        }
        return nil
    }

    @MainActor
    func startexecution() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            let update = MultipletasksPrimaryLogging(profile: structprofile,
                                                     hiddenID: -1,
                                                     configurations: localconfigurations,
                                                     validhiddenIDs: validhiddenIDs)
            let updateconfigurations = update.setCurrentDateonConfiguration(configrecords: configrecords)
            // Send date stamped configurations back to caller
            localupdateconfigurations(updateconfigurations)
            // Update logrecords
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            localexecuteasyncnoestimation?.asyncexecutealltasksnoestiamtioncomplete()
            Logger.process.info("class ExecuteTasksAsync: async execution is completed")
            return
        }
        if let localhiddenID = stackoftasktobeestimated?.removeLast() {
            if let config = getconfig(localhiddenID, localconfigurations) {
                let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .arg)
                guard arguments.count > 0 else { return }
                // Check if ShellOut is active
                if config.pretask?.isEmpty == false, config.executepretask == 1 {
                    let processshellout = RsyncProcessAsyncShellOut(arguments: arguments,
                                                                    config: config,
                                                                    processtermination: processterminationexecute)
                    await processshellout.executeProcess()
                } else {
                    let process = RsyncProcessAsync(arguments: arguments,
                                                    config: config,
                                                    processtermination: processterminationexecute)
                    await process.executeProcess()
                }
            }
        }
    }

    init(profile: String?,
         rsyncuiconfigurations: [SynchronizeConfiguration],
         executeasyncnoestimation: ExecuteAsyncNoEstimation?,
         uuids: Set<UUID>,
         filter: String,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
    {
        structprofile = profile
        localconfigurations = rsyncuiconfigurations
        localexecuteasyncnoestimation = executeasyncnoestimation
        localupdateconfigurations = updateconfigurations
        let filteredconfigurations = localconfigurations.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        stackoftasktobeestimated = [Int]()
        // Estimate selected configurations
        if uuids.count > 0 {
            let configurations = filteredconfigurations.filter { uuids.contains($0.id) }
            for i in 0 ..< configurations.count {
                stackoftasktobeestimated?.append(configurations[i].hiddenID)
            }
        } else {
            // Or estimate all tasks
            for i in 0 ..< filteredconfigurations.count {
                stackoftasktobeestimated?.append(filteredconfigurations[i].hiddenID)
            }
            for i in 0 ..< localconfigurations.count {
                validhiddenIDs.insert(localconfigurations[i].hiddenID)
            }
        }
    }
}

extension ExecuteTasksAsync {
    func processterminationexecute(outputfromrsync: [String]?, hiddenID: Int?) {
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        configrecords.append((hiddenID ?? -1, Date().en_us_string_from_date()))
        schedulerecords.append((hiddenID ?? -1, Numbers(outputfromrsync ?? []).stats()))
        if let config = getconfig(hiddenID ?? -1, localconfigurations) {
            let record = RemoteDataNumbers(hiddenID: hiddenID,
                                           outputfromrsync: outputfromrsync,
                                           config: config)
            localexecuteasyncnoestimation?.appendrecordexecutedlist(record)
            localexecuteasyncnoestimation?.appenduuid(config.id)

            Task {
                await self.startexecution()
            }
        }
    }
}

// swiftlint:enable line_length
