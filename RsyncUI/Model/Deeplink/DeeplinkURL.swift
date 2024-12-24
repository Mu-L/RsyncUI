//
//  DeeplinkURL.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/12/2024.
//

import Foundation
import OSLog

enum DeeplinknavigationError: LocalizedError {
    case invalidurl
    case invalidscheme
    case noaction

    var errorDescription: String? {
        switch self {
        case .invalidurl:
            "Invalid URL"
        case .invalidscheme:
            "Invalid URL scheme"
        case .noaction:
            "No action URL scheme"
        }
    }
}

enum Deeplinknavigation {
    case quicktask
    case loadprofile
}

struct DeeplinkQueryItem: Hashable {
    let host: Deeplinknavigation
    let queryItem: URLQueryItem?
}

struct DeeplinkURL: PropogateError {
    private func validateScheme(_ url: URL) throws -> URLComponents? {
        guard url.scheme == "rsyncuiapp" else { throw DeeplinknavigationError.invalidscheme }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            return components
        } else {
            throw DeeplinknavigationError.invalidurl
        }
    }

    private func thrownoaction() throws {
        throw DeeplinknavigationError.noaction
    }

    // rsyncuiapp://loadprofile?profile=Samsung
    // rsyncuiapp://quicktask
    func handleURL(_ url: URL) -> DeeplinkQueryItem? {
        Logger.process.info("App was opened via URL: \(url)")

        var components: URLComponents?

        do {
            components = try validateScheme(url)
        } catch let e {
            let error = e
            propogateerror(error: error)
        }

        if let components {
            if let host = components.host {
                Logger.process.info("Found host: \(host)")
                // Found ... loadprofile
                // Found ... quicktask and no queryItems
            }

            if let query = components.query {
                Logger.process.info("Found query: \(query)")
                // Found ... profile=test
            }

            if let queryItems = components.queryItems,
                queryItems.count == 1 {
                // Iterate through the query items and store them in the dictionary
                for queryItem in queryItems {
                    if let value = queryItem.value {
                        let name = queryItem.name
                        Logger.process.info("Found query item: \(name) with value: \(value)")
                        // Found ... profile ...value: test
                    }
                    let deepLinkQueryItem = DeeplinkQueryItem(host: .loadprofile, queryItem: queryItem)
                    return deepLinkQueryItem
                }
                
            } else {
                let deepLinkQueryItem = DeeplinkQueryItem(host: .quicktask, queryItem: nil)
                return deepLinkQueryItem
            }
            
            

            // Must have a RETURN VALUE  here

            do {
                try thrownoaction()
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
        return nil
    }
}
