import SwiftUI

struct AppStyles {
    static let cornerRadius: CGFloat = 16
    static let dashLength: CGFloat = 6
    static let dashSpacing: CGFloat = 4
    
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let surfaceColor = Color.clear
    static let borderColor = Color.white.opacity(0.2)
    static let glassMaterial = Material.ultraThin
    static let roundedCornerRadius: CGFloat = 22 // Softer, more Tahoe-like corners
}

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppStyles.roundedCornerRadius))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: AppStyles.roundedCornerRadius)
                    .stroke(AppStyles.borderColor, lineWidth: 1)
            )
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}
struct DropSquare: View {
    let title: String
    let icon: String // System icon name for placeholder
    let isSelected: Bool
    var appIcon: NSImage? = nil // Actual app icon if available
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: AppStyles.roundedCornerRadius)
                    .strokeBorder(isSelected ? Color.blue : AppStyles.borderColor, 
                                 style: StrokeStyle(lineWidth: 2, 
                                                   dash: isSelected ? [] : [AppStyles.dashLength, AppStyles.dashSpacing]))
                    .background(
                        RoundedRectangle(cornerRadius: AppStyles.roundedCornerRadius)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color.white.opacity(0.05))
                    )
                    .liquidGlass()
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                
                VStack(spacing: 12) {
                    if let appIcon = appIcon {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 44, weight: .light))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(isSelected ? .blue : .primary.opacity(0.6))
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(width: 180, height: 180)
            .onHover { hovering in
                isHovered = hovering
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(width: 180)
                .lineLimit(2)
        }
    }
}
