//
//  Profilenames.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/03/2021.
//

import Foundation

struct Profiles: Hashable {
    var profile: String?

    init(_ name: String) {
        profile = name
    }
}

final class Profilenames: ObservableObject {
    var profiles: [Profiles]?

    func update() {
        setprofilenames()
    }

    func setprofilenames() {
        let names = Catalogsandfiles(.configurations).getcatalogsasstringnames()
        profiles = []
        for i in 0 ..< (names?.count ?? 0) {
            profiles?.append(Profiles(names?[i] ?? ""))
        }
    }

    init() {
        setprofilenames()
    }
}
