//
//  FilterButton.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? .clear : Color(.quaternaryLabel), lineWidth: 1)
                )
                .shadow(
                    color: isSelected ? .blue.opacity(0.3) : .clear,
                    radius: isSelected ? 4 : 0,
                    x: 0,
                    y: isSelected ? 2 : 0
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            FilterButton(title: "All", isSelected: true) {}
            FilterButton(title: "Completed", isSelected: false) {}
            FilterButton(title: "Processing", isSelected: false) {}
        }
        .padding()
    }
}