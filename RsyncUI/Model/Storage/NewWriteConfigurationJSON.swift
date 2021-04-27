//
//  NewWriteConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//

import Combine
import Files
import Foundation

class NewWriteConfigurationJSON: NamesandPaths {
    var filenamedatastore = [SharedReference.shared.fileconfigurationsjson]
    var subscriptons = Set<AnyCancellable>()

    func writeJSONToPersistentStore(_ data: String?) {
        if var atpath = fullroot {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "")
                }
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: filename ?? "")
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

    init(_ profile: String?, _ configurations: [Configuration]?) {
        super.init(profileorsshrootpath: .profileroot)
        // Set profile and filename ahead of encoding an write
        self.profile = profile
        self.filename = SharedReference.shared.fileconfigurationsjson
        configurations.publisher
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
                // verifynewversion(result)
                let jsonfile = String(data: result, encoding: .utf8)
                writeJSONToPersistentStore(jsonfile)
            })
            .store(in: &subscriptons)
    }
}
