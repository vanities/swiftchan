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

struct MultiActionSheetModifier<Body: View>: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    var content: Body

    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Body) {
        self._isPresented = isPresented
        self.content = content()
    }

    func body(content: Content) -> some View {
        return ZStack {
            content
                .blur(radius: isPresented ? 2 : 0)
            Color.black.opacity(isPresented ? 0.2 : 0)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }

            if isPresented {
                VStack(spacing: 0) {
                    Spacer()

                    VStack {
                        self.content
                        HStack {
                            Spacer()
                            Text("Cancel")
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .bold()
                                .foregroundColor(.blue)
                                .padding(.bottom, 30)
                            Spacer()
                        }
                        .onTapGesture {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
                    .padding(.top, 20)
                    .background(colorScheme == .dark ?
                                Colors.Background.gray.cornerRadius(10) :
                                Colors.Background.white.cornerRadius(10)
                    )
                }
                .ignoresSafeArea()
                .zIndex(2)
                .transition(.move(edge: .bottom))
                .navigationBarHidden(true)
                .statusBar(hidden: true)
            }
        }
    }
}

extension View {
    func multiActionSheet<Content: View>(isPresented: Binding<Bool>, content: @escaping () -> Content) -> some View {
        self.modifier(MultiActionSheetModifier(isPresented: isPresented, content: content))
    }
}

struct MultiActionSheetView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            Color.white
                .multiActionSheet(isPresented: .constant(true)) {
                    FilesSortRow(viewModel: CatalogView.CatalogViewModel(boardName: "fit"))
                }
        }
    }
}
