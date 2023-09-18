//
//  RestoreFilesTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreFilesTableView: View {
    @EnvironmentObject var restore: ObservableRestore
    @State private var selectedid: RestoreFileRecord.ID?
    @Binding var filestorestore: String

    var body: some View {
        ZStack {
            Table(restore.datalist, selection: $selectedid) {
                TableColumn("Filenames", value: \.filename)
            }
            .onChange(of: selectedid) { _ in
                let record = restore.datalist.filter { $0.id == selectedid }
                guard record.count > 0 else { return }
                filestorestore = record[0].filename
            }
        }
    }
}
