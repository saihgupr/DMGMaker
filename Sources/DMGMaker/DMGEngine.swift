import Foundation
import AppKit
import SwiftUI

@MainActor
class DMGEngine: ObservableObject {
    @Published var isProcessing = false
    @Published var statusMessage = ""
    
    private func generateBackground(appName: String, size: NSSize) -> NSImage {
        let view = DMGBackgroundView(appName: appName)
            .frame(width: size.width, height: size.height)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // High DPI
        
        if let cgImage = renderer.cgImage {
            return NSImage(cgImage: cgImage, size: size)
        }
        
        // Fallback
        return NSImage(size: size)
    }
    
    func createDMG(appURL: URL, backgroundURL: URL?, outputName: String) {
        isProcessing = true
        statusMessage = "Preparing staging area..."
        
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
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let outputDMG = appURL.deletingLastPathComponent().appendingPathComponent("\(outputName).dmg")
        
        do {
            // 1. Create Staging & Asset Directory
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let assetsDir = tempDir.deletingLastPathComponent().appendingPathComponent("\(UUID().uuidString)-assets")
            try fileManager.createDirectory(at: assetsDir, withIntermediateDirectories: true)
            
            // 2. Prepare App in staging (Copy instead of symlink for better icon handling)
            let appName = appURL.lastPathComponent
            let stagingAppURL = tempDir.appendingPathComponent(appName)
            try fileManager.copyItem(at: appURL, to: stagingAppURL)
            
            // 3. Generate Background with Arrow (Outside staging to avoid duplication)
            let bgPath = assetsDir.appendingPathComponent("background.png")
            // New size 600x450 to accommodate instructions at bottom
            let bgImage = generateBackground(appName: outputName, size: NSSize(width: 600, height: 450))
            if let tiffData = bgImage.tiffRepresentation, 
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try pngData.write(to: bgPath)
            }
            
            // 4. Create Applications Symlink (Bypassing create-dmg's automatic halo)
            let appsSymlink = tempDir.appendingPathComponent("Applications")
            try fileManager.createSymbolicLink(at: appsSymlink, withDestinationURL: URL(fileURLWithPath: "/Applications"))
            try? fileManager.setAttributes([.extensionHidden: true], ofItemAtPath: appsSymlink.path)
            
            statusMessage = "Building DMG..."
            
            // 5. Create DMG
            try? fileManager.removeItem(at: outputDMG)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binPath)
            
            var arguments = [
                "--volname", outputName,
                "--window-pos", "200", "120",
                "--window-size", "600", "450",
                "--icon-size", "128",
                "--icon", appName, "150", "200", // Shifted to match glass track
                "--icon", "Applications", "450", "200", // Shifted to match glass track
                "--background", bgPath.path,
                "--hide-extension", appName,
                "--hide-extension", "Applications"
            ]
            
            arguments.append(contentsOf: [outputDMG.path, tempDir.path])
            process.arguments = arguments
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let exitCode = process.terminationStatus
                
                // Cleanup staging & asset dirs
                try? FileManager.default.removeItem(at: tempDir)
                try? FileManager.default.removeItem(at: assetsDir)
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if exitCode == 0 && FileManager.default.fileExists(atPath: outputDMG.path) {
                        self.statusMessage = "DMG created successfully"
                        NSWorkspace.shared.activateFileViewerSelecting([outputDMG])
                    } else {
                        print("DMG Creation Failed. Output:\n\(output)")
                        let cleanError = output.components(separatedBy: "\n")
                            .filter { !$0.isEmpty }
                            .last ?? "Unknown Error"
                        self.statusMessage = "Status \(exitCode): \(cleanError)"
                    }
                }
            }
            
            try process.run()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
            isProcessing = false
            // Attempts to clean up both potential dirs
            try? fileManager.removeItem(at: tempDir)
            // Note: We don't have easy access to assetsDir here in the catch block if it failed early, 
            // but we'll try to keep it simple.
        }
    }
}
