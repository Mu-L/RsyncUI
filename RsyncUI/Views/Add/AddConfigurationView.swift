//
//  AddConfigurationView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//

//
//  AddView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/03/2021.
//

import SwiftUI

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct AddConfigurationView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @EnvironmentObject var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @StateObject var newdata = ObserveableAddConfigurations()

    var body: some View {
        Form {
            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        pickerselecttypeoftask

                        if newdata.selectedrsynccommand == .syncremote {
                            VStack(alignment: .leading) { localandremotecatalogsyncremote }
                        } else {
                            VStack(alignment: .leading) { localandremotecatalog }
                        }

                        VStack(alignment: .leading) { synchronizeid }

                        VStack(alignment: .leading) { remoteuserandserver }
                    }

                    // Column 2
                    VStack(alignment: .leading) {
                        ToggleView("Don´t add /", $newdata.donotaddtrailingslash)
                    }

                    // Column 3

                    VStack(alignment: .leading) {
                        ConfigurationsListSmall(selectedconfig: $newdata.selectedconfig.onChange {
                            newdata.updateview()
                        })
                    }

                    // For center
                    Spacer()
                }

                // Present when either added, updated or profile created, deleted
                if newdata.added == true { notifyadded }
                if newdata.updated == true { notifyupdated }
                if newdata.created == true { notifycreated }
                if newdata.deleted == true { notifydeleted }
                if newdata.deletedefaultprofile == true { cannotdeletedefaultprofile }
            }

            Spacer()

            VStack {
                HStack {
                    adddeleteprofile

                    Spacer()

                    updatebutton
                }
            }
        }
        .lineSpacing(2)
        .padding()
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = "Default profile"
                reload = true
            }
        })
    }

    var updatebutton: some View {
        HStack {
            // Add or Update button
            if newdata.selectedconfig == nil {
                Button("Add") { addconfig() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                if newdata.inputchangedbyuser == true {
                    Button("Update") { validateandupdate() }
                        .buttonStyle(PrimaryButtonStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red, lineWidth: 5)
                        )
                } else {
                    Button("Update") {}
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    // Add and edit text values
    var setlocalcatalogsyncremote: some View {
        EditValue(300, "Add remote as local catalog - required",
                  $newdata.localcatalog)
    }

    var setremotecatalogsyncremote: some View {
        EditValue(300, "Add local as remote catalog - required",
                  $newdata.remotecatalog)
    }

    var setlocalcatalog: some View {
        EditValue(300, "Add local catalog - required",
                  $newdata.localcatalog)
            .textContentType(.none)
    }

    var setremotecatalog: some View {
        EditValue(300, "Add remote catalog - required",
                  $newdata.remotecatalog)
            .textContentType(.none)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            if newdata.selectedconfig == nil { setlocalcatalog } else {
                EditValue(300, nil, $newdata.localcatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
                    .onAppear(perform: {
                        if let catalog = newdata.selectedconfig?.localCatalog {
                            newdata.localcatalog = catalog
                        }
                    })
            }
            // remotecatalog
            if newdata.selectedconfig == nil { setremotecatalog } else {
                EditValue(300, nil, $newdata.remotecatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
                    .onAppear(perform: {
                        if let catalog = newdata.selectedconfig?.offsiteCatalog {
                            newdata.remotecatalog = catalog
                        }
                    })
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            if newdata.selectedconfig == nil {
                setlocalcatalogsyncremote
            } else {
                EditValue(300, nil, $newdata.localcatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .onAppear(perform: {
                        if let catalog = newdata.selectedconfig?.localCatalog {
                            newdata.localcatalog = catalog
                        }
                    })
            }
            // remotecatalog
            if newdata.selectedconfig == nil {
                setremotecatalogsyncremote
            } else {
                EditValue(300, nil, $newdata.remotecatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .onAppear(perform: {
                        if let catalog = newdata.selectedconfig?.offsiteCatalog {
                            newdata.remotecatalog = catalog
                        }
                    })
            }
        }
    }

    // Headers (in sections)

    var adddeleteprofile: some View {
        HStack {
            Button("Create") { createprofile() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Delete") { newdata.showAlertfordelete = true }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $newdata.showAlertfordelete) {
                    ConfirmDeleteProfileView(isPresented: $newdata.showAlertfordelete,
                                             delete: $newdata.confirmdeleteselectedprofile,
                                             profile: $rsyncUIdata.profile)
                        .onDisappear(perform: {
                            deleteprofile()
                        })
                }

            EditValue(150, "New profile",
                      $newdata.newprofile)
                .textContentType(.none)
        }
    }

    var setID: some View {
        EditValue(300, "Add synchronize ID",
                  $newdata.backupID)
            .textContentType(.none)
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
    }

    var synchronizeid: some View {
        Section(header: headerID) {
            // Synchronize ID
            if newdata.selectedconfig == nil { setID } else {
                EditValue(300, nil, $newdata.backupID.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
                    .onAppear(perform: {
                        if let id = newdata.selectedconfig?.backupID {
                            newdata.backupID = id
                        }
                    })
            }
        }
    }

    var setremoteuser: some View {
        EditValue(300, "Add remote user",
                  $newdata.remoteuser)
            .textContentType(.none)
    }

    var setremoteserver: some View {
        EditValue(300, "Add remote server",
                  $newdata.remoteserver)
            .textContentType(.none)
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if newdata.selectedconfig == nil { setremoteuser } else {
                EditValue(300, nil, $newdata.remoteuser.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
                    .onAppear(perform: {
                        if let user = newdata.selectedconfig?.offsiteUsername {
                            newdata.remoteuser = user
                        }
                    })
            }
            // Remote server
            if newdata.selectedconfig == nil { setremoteserver } else {
                EditValue(300, nil, $newdata.remoteserver.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
                    .onAppear(perform: {
                        if let server = newdata.selectedconfig?.offsiteServer {
                            newdata.remoteserver = server
                        }
                    })
            }
        }
    }

    var selectpickervalue: TypeofTask {
        switch newdata.selectedconfig?.task {
        case SharedReference.shared.synchronize:
            return .synchronize
        case SharedReference.shared.syncremote:
            return .syncremote
        case SharedReference.shared.snapshot:
            return .snapshot
        default:
            return .synchronize
        }
    }

    var pickerselecttypeoftask: some View {
        Picker("Task" + ":",
               selection: $newdata.selectedrsynccommand) {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
            .onChange(of: newdata.selectedconfig, perform: { _ in
                newdata.selectedrsynccommand = selectpickervalue
            })
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
    }

    var notifyadded: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Added"), subTitle: Optional(""))
    }

    var notifyupdated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Updated"), subTitle: Optional(""))
    }

    var notifycreated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Created"), subTitle: Optional(""))
    }

    var notifydeleted: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Deleted"), subTitle: Optional(""))
    }

    var cannotdeletedefaultprofile: some View {
        AlertToast(type: .error(Color.red),
                   title: Optional("Cannot delete default profile"), subTitle: Optional(""))
    }

    var configurations: [Configuration]? {
        return rsyncUIdata.rsyncdata?.configurationData.getallconfigurations()
    }
}

extension AddConfigurationView {
    func addconfig() {
        newdata.addconfig(selectedprofile, configurations)
        reload = newdata.reload
        if newdata.added == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.added = false
            }
        }
    }

    func createprofile() {
        newdata.createprofile()
        profilenames.update()
        selectedprofile = newdata.selectedprofile
        reload = true
        if newdata.created == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.created = false
            }
        }
    }

    func deleteprofile() {
        newdata.deleteprofile(selectedprofile)
        profilenames.update()
        reload = true
        selectedprofile = nil
        if newdata.deleted == true {
            profilenames.update()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.deleted = false
            }
        }
        if newdata.deletedefaultprofile == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.deletedefaultprofile = false
            }
        }
    }

    func validateandupdate() {
        newdata.validateandupdate(selectedprofile, configurations)
        reload = newdata.reload
        if newdata.updated == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.updated = false
            }
        }
    }
}
