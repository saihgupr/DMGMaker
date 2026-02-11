import SwiftUI

struct DMGBackgroundView: View {
    let appName: String
    let appsIconPath: String?
    let windowSize: CGSize = CGSize(width: 600, height: 450)
    
    var body: some View {
        ZStack {
            // 1. Mesh-style Professional Gradient
            MeshGradientView()
                .frame(width: windowSize.width, height: windowSize.height)
            
            // 2. Decorative elements (subtle glass circles)
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -150, y: -100)
            
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: 180, y: 120)

            VStack(spacing: 0) {
                Spacer()
                
                // 3. Central Instruction Area (Glass Track)
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    HStack(spacing: 40) {
                        // App Placement Area (Transparent - Finder will place real icon here)
                        Color.clear
                            .frame(width: 140, height: 140)
                        
                        // Modern Arrow
                        ArrowView()
                            .frame(width: 80, height: 30)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Applications Icon Area
                        ZStack {
                            if let iconPath = appsIconPath, let image = NSImage(contentsOfFile: iconPath) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 110, height: 110) // Slightly smaller to match squircle visual weight
                                    .offset(y: -5) // Offset to account for folder tab
                            }
                        }
                        .frame(width: 140, height: 140)
                    }
                }
                .frame(width: 520, height: 200)
                
                Spacer()
                    .frame(height: 40)
                
                // 4. Instructions
                VStack(spacing: 4) {
                    Text("To install \(appName),")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Text("drag the icon into the Applications folder")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .opacity(0.7)
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .frame(width: windowSize.width, height: windowSize.height)
    }
}

struct MeshGradientView: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.3),
                        Color(red: 0.15, green: 0.1, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                ZStack {
                    AngularGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2), .blue.opacity(0.3)], center: .center)
                        .blur(radius: 50)
                    
                    RadialGradient(colors: [.cyan.opacity(0.15), .clear], center: .topTrailing, startRadius: 0, endRadius: 500)
                        .blendMode(.plusLighter)
                }
            )
    }
}

struct ArrowView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let midY = geo.size.height / 2
                let width = geo.size.width
                
                // Line
                path.move(to: CGPoint(x: 0, y: midY))
                path.addLine(to: CGPoint(x: width - 15, y: midY))
                
                // Arrow head
                path.move(to: CGPoint(x: width - 20, y: midY - 12))
                path.addLine(to: CGPoint(x: width, y: midY))
                path.addLine(to: CGPoint(x: width - 20, y: midY + 12))
            }
            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
    }
}

#Preview {
    DMGBackgroundView(appName: "ExampleApp", appsIconPath: nil)
}
