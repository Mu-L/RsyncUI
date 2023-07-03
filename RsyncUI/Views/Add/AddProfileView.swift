//
//  AddProfile.swift
//  AddProfile
//
//  Created by Thomas Evensen on 04/09/2021.
//

import SwiftUI

struct AddProfileView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(RsyncUIconfigurations.self) private var rsyncUIdata

    @EnvironmentObject var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @StateObject var newdata = ObserveableAddConfigurations()
    @State private var uuidprofile = Set<Profiles.ID>()

    var body: some View {
        ZStack {
            VStack {
                Table(profilenames.profiles ?? [], selection: $uuidprofile.onChange {
                    let profile = profilenames.profiles?.filter { profiles in
                        uuidprofile.contains(profiles.id)
                    }
                    if (profile?.count ?? 0) == 1 {
                        if let profile = profile {
                            selectedprofile = profile[0].profile
                        }
                    }
                }) {
                    TableColumn("Profiles") { name in
                        Text(name.profile ?? "Default profile")
                    }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Selected profile:")
                        Text(rsyncUIdata.profile ?? SharedReference.shared.defaultprofile)
                            .foregroundColor(Color.blue)
                    }

                    HStack {
                        Button("Create") { createprofile() }
                            .buttonStyle(PrimaryButtonStyle())

                        EditValue(150, NSLocalizedString("Create profile", comment: ""),
                                  $newdata.newprofile)
                    }
                }

                Spacer()
            }
        }

        Spacer()

        HStack {
            Spacer()

            Button("Dismiss") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Delete") { newdata.showAlertfordelete = true }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $newdata.showAlertfordelete) {
                    ConfirmDeleteProfileView(isPresented: $newdata.showAlertfordelete,
                                             delete: $newdata.confirmdeleteselectedprofile,
                                             profile: rsyncUIdata.profile)
                        .onDisappear(perform: {
                            deleteprofile()
                        })
                }
        }
        .padding()
        .onSubmit {
            createprofile()
        }
    }
}

extension AddProfileView {
    func createprofile() {
        newdata.createprofile()
        profilenames.update()
        selectedprofile = newdata.selectedprofile
        reload = true
        dismiss()
    }

    func deleteprofile() {
        newdata.deleteprofile(selectedprofile)
        profilenames.update()
        reload = true
        selectedprofile = nil
        dismiss()
    }
}
