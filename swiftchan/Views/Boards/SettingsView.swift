//
//  SettingsView.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/7/21.
//

import SwiftUI
import ToastUI

struct SettingsView: View {
    @State var showCacheDeleteToast = false
    @State private var cacheResult: Result<Void, Error>?

    var body: some View {
        return ScrollView(.vertical) {
            HStack {
                VStack(alignment: .leading) {
                    Section(content: {
                        Button(
                            role: .destructive,
                            action: {
                                CacheManager.shared.deleteAll { result in
                                    cacheResult = result
                                    showCacheDeleteToast = true
                                }
                            },
                            label: {
                                Label("Delete Cache", systemImage: "trash")
                            }
                        )
                    }, header: {
                        Text("Cache")
                    })
                        .padding()
                }
                Spacer()
            }
        }
        .navigationTitle(Text("Settings"))
        .toast(isPresented: $showCacheDeleteToast,
               dismissAfter: 0.5,
               content: {
            Toast(presentingToastResult: cacheResult)
        })
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        return SettingsView()
    }
}
#endif
