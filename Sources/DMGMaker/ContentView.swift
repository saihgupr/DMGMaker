import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var engine = DMGEngine()
    @State private var appURL: URL?
    @State private var appIcon: NSImage?
    @State private var backgroundURL: URL?
    @State private var dmgName: String = "My App"
    
    var body: some View {
        ZStack {
            // Background material
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("DMG Maker")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                .padding(.top, 30)
                
                HStack(spacing: 30) {
                    // App Drop Zone
                    DropSquare(
                        title: appURL?.lastPathComponent ?? "Drop .app bundle",
                        icon: "app.badge",
                        isSelected: appURL != nil,
                        appIcon: appIcon
                    )
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleAppDrop(providers: providers)
                    }
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.3))
                    
                    // Background Image Drop Zone
                    DropSquare(
                        title: backgroundURL?.lastPathComponent ?? "Custom Background",
                        icon: "photo.on.rectangle.angled",
                        isSelected: backgroundURL != nil
                    )
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleBackgroundDrop(providers: providers)
                    }
                }
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Volume Name:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("My App", text: $dmgName)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(width: 250)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    Button(action: createDMG) {
                        HStack {
                            if engine.isProcessing {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 5)
                            }
                            Text(engine.isProcessing ? "Processing..." : "Create DMG")
                                .fontWeight(.semibold)
                        }
                        .frame(width: 200, height: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(appURL == nil || engine.isProcessing)
                }
                
                Text(engine.statusMessage)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(height: 20)
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func handleAppDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            if url.pathExtension == "app" {
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                DispatchQueue.main.async {
                    self.appURL = url
                    self.appIcon = icon
                    self.dmgName = url.deletingPathExtension().lastPathComponent
                }
            }
        }
        return true
    }
    
    private func handleBackgroundDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            let supported = ["png", "jpg", "jpeg", "tiff"]
            if supported.contains(url.pathExtension.lowercased()) {
                DispatchQueue.main.async {
                    self.backgroundURL = url
                }
            }
        }
        return true
    }
    
    private func createDMG() {
        guard let app = appURL else { return }
        engine.createDMG(appURL: app, backgroundURL: backgroundURL, outputName: dmgName)
    }
}
