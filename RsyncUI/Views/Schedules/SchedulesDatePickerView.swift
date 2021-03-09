//
//  SchedulesDatePickerView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 05/03/2021.
//

import Foundation
import SwiftUI

enum EnumScheduleDatePicker: String, CaseIterable, Identifiable, CustomStringConvertible {
    case once
    case daily
    case weekly

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

struct SchedulesDatePickerView: View {
    @Binding var selecteddate: Date
    @Binding var selectedscheduletype: EnumScheduleDatePicker

    var body: some View {
        HStack {
            DatePicker("", selection: $selecteddate,
                       in: Date()...,
                       displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()

            VStack(alignment: .leading) {
                Picker("", selection: $selectedscheduletype) {
                    ForEach(EnumScheduleDatePicker.allCases) { Text($0.description)
                        .tag($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                .labelsHidden()

                Text(startdate) + Text("\(selecteddate.localized_string_from_date())")
                    .foregroundColor(Color.blue)
                Text(schedule) + Text("\(selectedscheduletype.rawValue)")
                    .foregroundColor(Color.blue)
            }
        }
    }

    var startdate: String {
        NSLocalizedString("Start date is", comment: "SchedulesDatePickerView") + ": "
    }

    var schedule: String {
        NSLocalizedString("Schedule is", comment: "SchedulesDatePickerView") + ": "
    }
}
