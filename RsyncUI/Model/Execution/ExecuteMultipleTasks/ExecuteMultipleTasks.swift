//
//  ExecuteMultipleTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//
// swiftlint:disable line_length

import Foundation

typealias Typelogdata = (Int, String)

enum ExecutetaskWork: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case execute
    case completed
    case error

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

final class ExecuteMultipleTasks {
    private var localconfigurations: RsyncUIconfigurations?
    private var structprofile: String?
    private var privatehiddenID: Int?
    private var stackoftasktobeexecuted: [Int]?
    private var records: [RemoteinfonumbersOnetask]?
    private var max: Int?
    // Set if abort is executed
    private var setabort = false
    // output from rsync
    private var outputfromrsync: [String]?

    weak var multipletasksateDelegate: MultipleTaskState?
    weak var updateestimationcountDelegate: UpdateEstimationCount?
    // In progress count each task
    weak var updateprogessDelegate: ExecuteDetailsProtocol?

    // Collect loggdata for later save to permanent storage
    // (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()

    private func prepareandstartexecutetasks(configurations: [Configuration]?) {
        stackoftasktobeexecuted = [Int]()
        // Multiple selected indexes
        if let configurations = configurations {
            for i in 0 ..< configurations.count {
                stackoftasktobeexecuted?.append(configurations[i].hiddenID)
            }
            max = stackoftasktobeexecuted?.count
            updateestimationcountDelegate?.setmaxcount(num: stackoftasktobeexecuted?.count ?? 0)
        }
    }

    private func startexecution() {
        guard (stackoftasktobeexecuted?.count ?? 0) > 0 else { return }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            privatehiddenID = hiddenID
            updateestimationcountDelegate?.sethiddenID(hiddenID)
            let estimation = ExecuteOneTask(hiddenID: hiddenID,
                                            configurations: localconfigurations,
                                            termination: processtermination,
                                            filehandler: filehandler)
            estimation.startexecution()
        }
    }

    private func getconfig(hiddenID: Int?) -> Configuration? {
        if let hiddenID = hiddenID {
            if let configurations = localconfigurations?.getallconfigurations()?.filter({ $0.hiddenID == hiddenID }) {
                guard configurations.count == 1 else { return nil }
                return configurations[0]
            }
        }
        return nil
    }

    @discardableResult
    init(uuids: Set<UUID>,
         profile: String?,
         configurations: RsyncUIconfigurations?,
         executionstateDelegate: MultipleTaskState?,
         updateinprogresscount: UpdateEstimationCount?,
         singletaskupdate: ExecuteDetailsProtocol?)
    {
        structprofile = profile
        localconfigurations = configurations
        multipletasksateDelegate = executionstateDelegate
        updateestimationcountDelegate = updateinprogresscount
        updateprogessDelegate = singletaskupdate
        guard uuids.count > 0 else { return }
        guard localconfigurations?.getallconfigurations()?.filter({ uuids.contains($0.id) }).count ?? 0 > 0 else { return }
        prepareandstartexecutetasks(configurations: localconfigurations?.getallconfigurations()?.filter { uuids.contains($0.id) })
        records = [RemoteinfonumbersOnetask]()
        startexecution()
    }

    deinit {
        self.stackoftasktobeexecuted = nil
    }

    func abort() {
        stackoftasktobeexecuted = nil
        updateestimationcountDelegate?.resetcounts()
        setabort = true
    }

    func processtermination(data: [String]?, hiddenID _: Int?) {
        guard setabort == false else { return }
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        configrecords.append((privatehiddenID ?? -1, Date().en_us_string_from_date()))
        schedulerecords.append((privatehiddenID ?? -1, Numbers(data ?? []).stats()))
        // Log records
        updateestimationcountDelegate?.updateinprogresscount(num: Double((max ?? 0) - (stackoftasktobeexecuted?.count ?? 0)))
        let record = RemoteinfonumbersOnetask(hiddenID: privatehiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: getconfig(hiddenID: privatehiddenID))
        records?.append(record)
        guard stackoftasktobeexecuted?.count ?? 0 > 0 else {
            multipletasksateDelegate?.updatestate(state: .completed)
            updateestimationcountDelegate?.setmaxcount(num: 0)
            updateestimationcountDelegate?.setestimatedlist(records)
            let update = MultipletasksPrimaryLogging(profile: structprofile,
                                                     hiddenID: privatehiddenID,
                                                     configurations: localconfigurations?.getallconfigurations(),
                                                     validhiddenIDs: localconfigurations?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration(configrecords: configrecords)
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            return
        }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            privatehiddenID = hiddenID
            updateestimationcountDelegate?.sethiddenID(hiddenID)
            let execution = ExecuteOneTask(hiddenID: hiddenID,
                                           configurations: localconfigurations,
                                           termination: processtermination,
                                           filehandler: filehandler)
            execution.startexecution()
        }
    }

    func filehandler(count: Int) {
        updateprogessDelegate?.setcurrentprogress(Double(count))
    }
}

// swiftlint:enable line_length
