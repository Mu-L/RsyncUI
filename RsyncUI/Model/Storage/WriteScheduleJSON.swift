//
//  WriteScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//

import Combine
import Files
import Foundation

class WriteScheduleJSON: NamesandPaths {
    var subscriptons = Set<AnyCancellable>()
    // Filename for JSON file
    var filename = SharedReference.shared.fileschedulesjson

    private func writeJSONToPersistentStore(_ data: String?) {
        if var atpath = fullpathmacserial {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "")
                }
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: filename)
                if let data = data {
                    try file.write(data)
                    if SharedReference.shared.menuappisrunning {
                        Notifications().showNotification(SharedReference.shared.reloadstring)
                        DistributedNotificationCenter.default()
                            .postNotificationName(NSNotification.Name(SharedReference.shared.reloadstring),
                                                  object: nil, deliverImmediately: true)
                    }
                }
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    // We have to remove UUID and computed properties ahead of writing JSON file
    // done in .map operator
    @discardableResult
    init(_ profile: String?, _ schedules: [ConfigurationSchedule]?) {
        super.init(.configurations)
        // Set profile and filename ahead of encoding an write
        self.profile = profile
        schedules.publisher
            .map { what -> [DecodeSchedule] in
                var data = [DecodeSchedule]()
                for i in 0 ..< what.count {
                    data.append(DecodeSchedule(what[i]))
                }
                return data
            }
            .encode(encoder: JSONEncoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] result in
                let jsonfile = String(data: result, encoding: .utf8)
                writeJSONToPersistentStore(jsonfile)
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}
