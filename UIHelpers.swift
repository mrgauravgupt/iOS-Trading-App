import SwiftUI

// Enhanced Trading App Color Palette
extension Color {
    static let kiteBlue = Color(red: 0/255, green: 122/255, blue: 255/255)
    static let kiteBackground = Color(.systemGroupedBackground)
    
    // Professional Trading Colors
    static let tradingGreen = Color(red: 0/255, green: 200/255, blue: 83/255)
    static let tradingRed = Color(red: 255/255, green: 59/255, blue: 48/255)
    static let tradingOrange = Color(red: 255/255, green: 149/255, blue: 0/255)
    static let tradingPurple = Color(red: 175/255, green: 82/255, blue: 222/255)
    static let tradingYellow = Color(red: 255/255, green: 204/255, blue: 0/255)
    
    // Dark Theme Colors
    static let darkCardBackground = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let darkSecondaryBackground = Color(red: 44/255, green: 44/255, blue: 46/255)
    static let darkTertiaryBackground = Color(red: 58/255, green: 58/255, blue: 60/255)
    
    // Gradient Colors
    static let primaryGradientStart = Color(red: 0/255, green: 122/255, blue: 255/255)
    static let primaryGradientEnd = Color(red: 88/255, green: 86/255, blue: 214/255)
}

// Enhanced card container with modern design
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
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// Enhanced metric chip with modern design
struct StatChip: View {
    let label: String
    let value: String
    var color: Color = .primary
    var backgroundColor: Color = Color(.secondarySystemBackground)

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Additional Modern Components

struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct PulsingDot: View {
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}