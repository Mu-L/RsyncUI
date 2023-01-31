//
//  SidebarMultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct SidebarTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedconfig: Configuration?
    @Binding var reload: Bool
    // Which sidebar function
    @Binding var selection: NavigationItem?
    @State var showestimateview: Bool = true

    @State var showexecutenoestimateview: Bool = false

    @State private var selecteduuids = Set<UUID>()
    // Show completed
    @State private var showcompleted: Bool = false

    var body: some View {
        ZStack {
            VStack {
                headingtitle

                if showestimateview == true && showexecutenoestimateview == false {
                    TasksView(selectedconfig: $selectedconfig,
                              reload: $reload,
                              selecteduuids: $selecteduuids,
                              showestimateview: $showestimateview,
                              showcompleted: $showcompleted,
                              showexecutenoestimateview: $showexecutenoestimateview,
                              selection: $selection)
                }

                if showestimateview == false && showexecutenoestimateview == false {
                    ExecuteEstimatedTasksView(selecteduuids: $selecteduuids,
                                              reload: $reload,
                                              showestimateview: $showestimateview)
                        .onDisappear(perform: {
                            showcompleted = true
                        })
                }

                if showexecutenoestimateview == true {
                    ExecuteNoestimatedTasksView(selectedconfig: $selectedconfig,
                                                reload: $reload,
                                                selecteduuids: $selecteduuids,
                                                showcompleted: $showcompleted,
                                                showexecutenoestimateview: $showexecutenoestimateview)
                        .onDisappear(perform: {
                            showcompleted = true
                        })
                }
            }
            .padding()

            if showcompleted {
                AlertToast(type: .complete(Color.green),
                           title: Optional("Completed"), subTitle: Optional(""))
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showcompleted = false
                        }
                    })
            }
        }
    }

    var headingtitle: some View {
        HStack {
            imagerssync

            VStack(alignment: .leading) {
                Text("Synchronize")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
    }

    var imagerssync: some View {
        Image("rsync")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 48)
            .padding(.bottom, 10)
    }
}
