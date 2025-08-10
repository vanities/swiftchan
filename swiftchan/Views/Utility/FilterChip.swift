//
//  FilterChip.swift
//  swiftchan
//
//  Created for search filtering
//

import SwiftUI

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
#Preview {
    VStack {
        FilterChip(label: "Has Media", isSelected: true, action: {})
        FilterChip(label: "Has Replies", isSelected: false, action: {})
    }
}
#endif