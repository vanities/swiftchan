//
//  MultiActionSheet.swift
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(Colors.Background.gray)
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
                .padding()
            }
            .onTapGesture {
                tapped()
            }
        }
        .frame(height: 50)
    }
}

struct MultiActionSheetModifier<Body: View>: ViewModifier {
    @Binding var isPresented: Bool
    var content: Body

    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Body) {
        self._isPresented = isPresented
        self.content = content()
    }

    func body(content: Content) -> some View {
        return ZStack {
            content
                .opacity(isPresented ? 0.3 : 1)
            if isPresented {
                VStack {
                    Spacer()
                    Group {
                        self.content
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Colors.Background.gray)
                                Text("Cancel")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .bold()
                                    .foregroundColor(.blue)
                            }
                            .onTapGesture {
                                withAnimation {
                                    isPresented = false
                                }
                            }
                        }
                        .frame(height: 50)
                    }
                }
                .zIndex(2)
                .transition(.move(edge: .bottom))
                .navigationBarHidden(true)
            }
        }
    }
}

extension View {
    func multiActionSheet<Content: View>(isPresented: Binding<Bool>, content: @escaping () -> Content) -> some View {
        self.modifier(MultiActionSheetModifier(isPresented: isPresented, content: content))
    }
}
