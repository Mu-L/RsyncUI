//
//  ButtonStyles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/03/2021.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    typealias ButtonConfiguration = ButtonStyleConfiguration

    func makeBody(configuration: ButtonConfiguration) -> some View {
        configuration.label
            .padding(8)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.5) : Color.accentColor)
            .foregroundColor(.white)
            .buttonBorderShape(.roundedRectangle)
            .clipShape(Capsule())
            // .overlay(
            //    RoundedRectangle(cornerRadius: 10)
            //        .stroke(Color.accentColor, lineWidth: 3)
            // )
            .onHover { hover in
                hover ? NSCursor.pointingHand.push() : NSCursor.pop()
            }
    }
}

struct AbortButtonStyle: ButtonStyle {
    typealias ButtonConfiguration = ButtonStyleConfiguration

    func makeBody(configuration: ButtonConfiguration) -> some View {
        configuration.label
            .padding(8)
            .background(configuration.isPressed ? Color.red.opacity(0.5) : Color.red)
            .foregroundColor(.white)
            .buttonBorderShape(.roundedRectangle)
            .clipShape(Capsule())
            // .overlay(
            //    RoundedRectangle(cornerRadius: 10)
            //        .stroke(Color.red, lineWidth: 3)
            // )
            .onHover { hover in
                hover ? NSCursor.pointingHand.push() : NSCursor.pop()
            }
    }
}

struct SaveButtonStyle: ButtonStyle {
    typealias ButtonConfiguration = ButtonStyleConfiguration

    func makeBody(configuration: ButtonConfiguration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.red.opacity(0.9) : Color.red)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.green, lineWidth: 3)
            )
            .onHover { hover in
                hover ? NSCursor.pointingHand.push() : NSCursor.pop()
            }
    }
}
