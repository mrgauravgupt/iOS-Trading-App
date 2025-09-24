import SwiftUI

// Zerodha-like palette
extension Color {
    static let kiteBlue = Color(red: 0/255, green: 122/255, blue: 255/255) // system blue
    static let kiteBackground = Color(.systemGroupedBackground)
}

// A simple card container used across screens
struct SectionCard<Content: View>: View {
    let title: String?
    let content: Content
    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Compact metric chip
struct StatChip: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline).bold()
                .foregroundStyle(color)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}