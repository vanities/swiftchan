//
//  SearchTextView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import SwiftUI

struct SearchTextView: View {
    let textPlaceholder: String
    @Binding var searchText: String

    var body: some View {
        return VStack {
            HStack {
                TextField(self.textPlaceholder, text: self.$searchText)
                    .padding(.horizontal, 40)
                    .frame(width: UIScreen.main.bounds.width-15, height: 45, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipped()
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 16)
                        }
                    )
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct SearchTextView_Previews: PreviewProvider {
    static var previews: some View {
        return SearchTextView(textPlaceholder: "Enter text here",
                              searchText: .constant(""))
    }
}
