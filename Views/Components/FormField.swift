//
//  FormField.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

import SwiftUI

struct FormField: View {
    var icon: String
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var prefix: String? = nil
    var isAutofilled: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isAutofilled ? .blue : .accentColor)
                    .frame(width: 20)
                
                if let prefix = prefix {
                    Text(prefix)
                        .foregroundColor(.secondary)
                        .font(.headline)
                }
                
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .foregroundColor(isAutofilled ? .blue : .primary)
                
                if isAutofilled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : (isAutofilled ? Color.blue.opacity(0.05) : Color.white))
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAutofilled ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
}
