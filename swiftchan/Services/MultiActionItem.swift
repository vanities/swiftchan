//
//  MultiActionItem.swift
//  swiftchan
//
//  Created by vanities on 10/15/21.
//

import SwiftUI

struct MultiActionItem<Icon: View, IconAnimation: View>: View {
    enum IconAnimationPlacement {
        case zstack, hstack
    }

    var icon: Icon
    var iconAnimation: IconAnimation?
    var iconAnimationPlacement: IconAnimationPlacement = .zstack
    var text: Text
    var tapped: (() -> Void)

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                HStack(alignment: .top) {
                    ZStack {
                        icon
                        if iconAnimationPlacement == .zstack {
                            iconAnimation
                        }
                    }
                    if iconAnimationPlacement == .hstack {
                        iconAnimation
                    }
                    VStack(alignment: .leading) {
                        text
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .foregroundColor(.blue)
                            .offset(x: 10)
                        Divider()
                    }
                }
            }
            .onTapGesture {
                tapped()
            }
        }
        .padding()
        .frame(height: 50)
    }
}
