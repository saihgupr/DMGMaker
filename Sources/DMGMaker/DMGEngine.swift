import Foundation
import AppKit

@MainActor
class DMGEngine: ObservableObject {
    @Published var isProcessing = false
    @Published var statusMessage = ""
    
    private func generateBackground(size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // 1. Draw Random Gradient
        let colors = [
            NSColor(calibratedHue: CGFloat.random(in: 0...1), saturation: 0.7, brightness: 0.9, alpha: 1.0).cgColor,
            NSColor(calibratedHue: CGFloat.random(in: 0...1), saturation: 0.6, brightness: 0.8, alpha: 1.0).cgColor,
            NSColor(calibratedHue: CGFloat.random(in: 0...1), saturation: 0.5, brightness: 0.7, alpha: 1.0).cgColor
        ]
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 0.5, 1.0])!
        
        context.drawLinearGradient(gradient, 
                                   start: CGPoint(x: 0, y: 0), 
                                   end: CGPoint(x: size.width, y: size.height), 
                                   options: [])
        
         // 2. Draw Professional Install Arrow
        let arrowY: CGFloat = 200
        let arrowStartX: CGFloat = 205
        let arrowEndX: CGFloat = 405
        
        context.saveGState()
        
        // Draw arrow shaft with gradient effect
        context.setLineWidth(6)
        context.setLineCap(.round)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.9).cgColor)
        context.move(to: CGPoint(x: arrowStartX, y: arrowY))
        context.addLine(to: CGPoint(x: arrowEndX - 25, y: arrowY))
        context.strokePath()
        
        // Draw filled arrow head (triangle) - smoother proportions
        let arrowHeadPath = CGMutablePath()
        arrowHeadPath.move(to: CGPoint(x: arrowEndX, y: arrowY))
        arrowHeadPath.addLine(to: CGPoint(x: arrowEndX - 25, y: arrowY - 15))
        arrowHeadPath.addLine(to: CGPoint(x: arrowEndX - 25, y: arrowY + 15))
        arrowHeadPath.closeSubpath()
        
        context.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
        context.addPath(arrowHeadPath)
        context.fillPath()
        
        context.restoreGState()
        
        // 3. Draw Applications Folder Icon
        let appIcon: NSImage
        if let iconURL = Bundle.module.url(forResource: "applications-folder", withExtension: "png"),
           let customImage = NSImage(contentsOf: iconURL) {
            appIcon = customImage
        } else {
            appIcon = NSWorkspace.shared.icon(forFile: "/Applications")
        }
        
        let iconSize: CGFloat = 120 // Slightly smaller than 128 to match create-dmg spacing
        let iconRect = CGRect(x: 480 - (iconSize / 2), y: 200 - (iconSize / 2), width: iconSize, height: iconSize)
        
        appIcon.draw(in: iconRect)
        
        // 4. Add "Drag to Applications" Label
        let text = "Drag to Applications" as NSString
        let font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        let textColor = NSColor.white.withAlphaComponent(0.95)
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 2
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .shadow: shadow
        ]

        let textSize = text.size(withAttributes: textAttributes)
        // Center text horizontally, position below the icons
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: 110,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: textAttributes)
        
        image.unlockFocus()
        return image
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
            // 1. Create Staging Directory
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // 2. Prepare App in staging (Copy instead of symlink for better icon handling)
            let appName = appURL.lastPathComponent
            let stagingAppURL = tempDir.appendingPathComponent(appName)
            try fileManager.copyItem(at: appURL, to: stagingAppURL)
            
            // 3. Generate Background with Arrow
            let bgPath = tempDir.appendingPathComponent("background.png")
            let bgImage = generateBackground(size: NSSize(width: 600, height: 400))
            if let tiffData = bgImage.tiffRepresentation, 
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try pngData.write(to: bgPath)
            }
            
            statusMessage = "Building DMG..."
            
            // 4. Create DMG
            try? fileManager.removeItem(at: outputDMG)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binPath)
            
            var arguments = [
                "--volname", outputName,
                "--window-pos", "200", "120",
                "--window-size", "600", "400",
                "--icon-size", "128",
                "--icon", appName, "120", "200",
                "--app-drop-link", "480", "200",
                "--background", bgPath.path
            ]
            
            arguments.append(contentsOf: [outputDMG.path, tempDir.path])
            process.arguments = arguments
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                // Cleanup staging dir
                try? FileManager.default.removeItem(at: tempDir)
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if FileManager.default.fileExists(atPath: outputDMG.path) {
                        self.statusMessage = "DMG created successfully"
                        NSWorkspace.shared.activateFileViewerSelecting([outputDMG])
                    } else {
                        let cleanError = output.components(separatedBy: "\n")
                            .filter { !$0.isEmpty }
                            .last ?? "Unknown Error"
                        self.statusMessage = "Failed: \(cleanError)"
                    }
                }
            }
            
            try process.run()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
            isProcessing = false
            try? fileManager.removeItem(at: tempDir)
        }
    }
}
