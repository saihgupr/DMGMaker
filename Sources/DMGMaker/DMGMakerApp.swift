import SwiftUI

@main
struct DMGMakerApp: App {
    @StateObject private var engine = DMGEngine()
    
    init() {
        let args = CommandLine.arguments
        if let appIdx = args.firstIndex(of: "--app"), appIdx + 1 < args.count,
           let nameIdx = args.firstIndex(of: "--name"), nameIdx + 1 < args.count {
            
            let appPath = args[appIdx + 1]
            let dmgName = args[nameIdx + 1]
            
            print("Running CLI Mode")
            print("App: \(appPath)")
            print("Volume Name: \(dmgName)")
            
            let appURL = URL(fileURLWithPath: appPath)
            
            // Run on main actor because engine is @MainActor
            Task { @MainActor in
                let engine = DMGEngine()
                engine.createDMG(appURL: appURL, backgroundURL: nil, outputName: dmgName)
                
                // Poll for completion
                while engine.isProcessing {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                
                print("\(engine.statusMessage)")
                exit(engine.statusMessage.contains("Error") ? 1 : 0)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("--app") {
                // Return a dummy view while CLI is running to satisfy SwiftUI
                Color.clear
                    .onAppear {
                        // The logic is in init() Task, but we need to stay alive
                    }
            } else {
                ContentView()
                    .frame(minWidth: 600, minHeight: 500)
                    .background(TransparentWindowView())
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

struct TransparentWindowView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
