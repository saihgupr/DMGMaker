import Foundation
import AppKit

@MainActor
class DMGEngine: ObservableObject {
    @Published var isProcessing = false
    @Published var statusMessage = ""
    
    func createDMG(appURL: URL, backgroundURL: URL?, outputName: String) {
        isProcessing = true
        statusMessage = "Starting DMG creation..."
        
        // Find create-dmg
        let paths = ["/opt/homebrew/bin/create-dmg", "/usr/local/bin/create-dmg"]
        var createDmgPath: String?
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                createDmgPath = path
                break
            }
        }
        
        guard let binPath = createDmgPath else {
            statusMessage = "Error: create-dmg not found. Please install via brew."
            isProcessing = false
            return
        }
        
        let outputDMG = appURL.deletingLastPathComponent().appendingPathComponent("\(outputName).dmg")
        
        // Remove existing DMG if it exists
        try? FileManager.default.removeItem(at: outputDMG)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binPath)
        
        var arguments = [
            "--volname", outputName,
            "--window-pos", "200", "120",
            "--window-size", "600", "400",
            "--icon-size", "128",
            "--app-drop-link", "425", "200",
            "--icon", appURL.deletingPathExtension().lastPathComponent, "175", "200"
        ]
        
        var debugInfo = ""
        if let bg = backgroundURL {
            arguments.append(contentsOf: ["--background", bg.path])
            debugInfo = "Using custom background"
        } else {
            let possiblePaths = [
                Bundle.module.path(forResource: "DefaultBackground", ofType: "png"),
                Bundle.main.path(forResource: "DefaultBackground", ofType: "png"),
                "Sources/DMGMaker/DefaultBackground.png",
                "DefaultBackground.png",
                "./DefaultBackground.png"
            ]
            
            if let foundPath = possiblePaths.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0) }) {
                arguments.append(contentsOf: ["--background", foundPath])
                debugInfo = "Using bundled background"
            } else {
                debugInfo = "No background found"
            }
        }
        
        arguments.append(contentsOf: [outputDMG.path, appURL.path])
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            DispatchQueue.main.async {
                self.isProcessing = false
                if FileManager.default.fileExists(atPath: outputDMG.path) {
                    self.statusMessage = "Success! (\(debugInfo))"
                    NSWorkspace.shared.activateFileViewerSelecting([outputDMG])
                } else {
                    let cleanError = output.components(separatedBy: "\n")
                        .filter { !$0.isEmpty }
                        .last ?? "Unknown Error"
                    self.statusMessage = "Failed: \(cleanError) (\(debugInfo))"
                    print("Full error: \(output)")
                }
            }
        }
        
        do {
            try process.run()
            statusMessage = "Running create-dmg..."
        } catch {
            statusMessage = "Process error: \(error.localizedDescription)"
            isProcessing = false
        }
    }
}
