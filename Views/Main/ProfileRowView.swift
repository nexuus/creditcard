import SwiftUI

struct ProfileRowView: View {
    let profile: UserProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile avatar
            ZStack {
                Circle()
                    .fill(colorFromString(profile.themePreference.accentColor).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: profile.avatar)
                    .font(.system(size: 20))
                    .foregroundColor(colorFromString(profile.themePreference.accentColor))
            }
            
            // Profile details
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                
                Text(profile.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Active indicator
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
            }
            
            // Delete button (only show if not active)
            if !isActive {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                        .padding(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Profile"),
                message: Text("Are you sure you want to delete this profile? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    onDelete()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Helper to convert color string to Color
    func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}