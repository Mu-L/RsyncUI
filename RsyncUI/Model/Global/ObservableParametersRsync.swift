//
//  ObservableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import Combine
import Foundation

@MainActor
final class ObservableParametersRsync: ObservableObject {
    // Rsync parameters
    @Published var parameter8: String = ""
    @Published var parameter9: String = ""
    @Published var parameter10: String = ""
    @Published var parameter11: String = ""
    @Published var parameter12: String = ""
    @Published var parameter13: String = ""
    @Published var parameter14: String = ""

    // Buttons
    @Published var suffixlinux: Bool = false
    @Published var suffixfreebsd: Bool = false
    @Published var backup: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()
    // Selected configuration
    @Published var configuration: Configuration?

    // Alerts
    @Published var alerterror: Bool = false
    @Published var error: Error = Validatedpath.noerror

    init() {
        $parameter8
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] parameter in
                configuration?.parameter8 = parameter
            }.store(in: &subscriptions)
        $parameter9
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] parameter in
                configuration?.parameter9 = parameter
            }.store(in: &subscriptions)
        $parameter10
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] parameter in
                configuration?.parameter10 = parameter
            }.store(in: &subscriptions)
        $parameter11
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] parameter in
                configuration?.parameter11 = parameter
            }.store(in: &subscriptions)
        $parameter12
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] parameter in
                configuration?.parameter12 = parameter
            }.store(in: &subscriptions)
        $parameter13
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] parameter in
                configuration?.parameter13 = parameter
            }.store(in: &subscriptions)
        $parameter14
            .sink { [unowned self] parameter in
                configuration?.parameter14 = parameter
            }.store(in: &subscriptions)
        $suffixlinux
            .sink { [unowned self] _ in
                setsuffixlinux()
            }.store(in: &subscriptions)
        $suffixfreebsd
            .sink { [unowned self] _ in
                setsuffixfreebsd()
            }.store(in: &subscriptions)
        $backup
            .sink { [unowned self] _ in
                setbackup()
            }.store(in: &subscriptions)
    }
}

extension ObservableParametersRsync {
    func setvalues(_ config: Configuration?) {
        if let config = config {
            configuration = config
            parameter8 = configuration?.parameter8 ?? ""
            parameter9 = configuration?.parameter9 ?? ""
            parameter10 = configuration?.parameter10 ?? ""
            parameter11 = configuration?.parameter11 ?? ""
            parameter12 = configuration?.parameter12 ?? ""
            parameter13 = configuration?.parameter13 ?? ""
            parameter14 = configuration?.parameter14 ?? ""
        } else {
            reset()
        }
    }

    func setbackup() {
        if let config = configuration {
            let localcatalog = config.localCatalog
            let localcatalogparts = (localcatalog as AnyObject).components(separatedBy: "/")
            if parameter12.isEmpty == false {
                parameter12 = ""
            } else {
                parameter12 = RsyncArguments().backupstrings[0]
            }
            guard localcatalogparts.count > 2 else { return }
            if config.offsiteCatalog.contains("~") {
                if parameter13.isEmpty == false {
                    parameter13 = ""
                } else {
                    parameter13 = RsyncArguments().backupstrings[1] + "_"
                        + localcatalogparts[localcatalogparts.count - 2]
                }
            } else {
                if parameter13.isEmpty == false {
                    parameter13 = ""
                } else {
                    parameter13 = RsyncArguments().backupstrings[2] + "_"
                        + localcatalogparts[localcatalogparts.count - 2]
                }
            }
            configuration?.parameter12 = parameter12
            configuration?.parameter13 = parameter13
        }
    }

    func setsuffixlinux() {
        guard configuration != nil else { return }
        if parameter14.isEmpty == false {
            if parameter14 == RsyncArguments().suffixstringfreebsd {
                parameter14 = RsyncArguments().suffixstringlinux
            } else {
                parameter14 = ""
            }
        } else {
            parameter14 = RsyncArguments().suffixstringlinux
        }
        configuration?.parameter14 = parameter14
    }

    func setsuffixfreebsd() {
        guard configuration != nil else { return }
        if parameter14.isEmpty == false {
            if parameter14 == RsyncArguments().suffixstringlinux {
                parameter14 = RsyncArguments().suffixstringfreebsd
            } else {
                parameter14 = ""
            }
        } else {
            parameter14 = RsyncArguments().suffixstringfreebsd
        }
        configuration?.parameter14 = parameter14
    }

    // Return the updated configuration
    func updatersyncparameters() -> Configuration? {
        if var configuration = configuration {
            if parameter8.isEmpty { configuration.parameter8 = nil } else { configuration.parameter8 = parameter8 }
            if parameter9.isEmpty { configuration.parameter9 = nil } else { configuration.parameter9 = parameter9 }
            if parameter10.isEmpty { configuration.parameter10 = nil } else { configuration.parameter10 = parameter10 }
            if parameter11.isEmpty { configuration.parameter11 = nil } else { configuration.parameter11 = parameter11 }
            if parameter12.isEmpty { configuration.parameter12 = nil } else { configuration.parameter12 = parameter12 }
            if parameter13.isEmpty { configuration.parameter13 = nil } else { configuration.parameter13 = parameter13 }
            if parameter14.isEmpty { configuration.parameter14 = nil } else { configuration.parameter14 = parameter14 }
            return configuration
        }
        return nil
    }

    func reset() {
        configuration = nil
        parameter8 = ""
        parameter9 = ""
        parameter10 = ""
        parameter11 = ""
        parameter12 = ""
        parameter13 = ""
        parameter14 = ""
    }
}

enum ParameterError: LocalizedError {
    case notvalid

    var errorDescription: String? {
        switch self {
        case .notvalid:
            return "Not a valid "
        }
    }
}
