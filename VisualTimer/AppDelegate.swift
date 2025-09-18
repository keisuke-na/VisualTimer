import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowDelegate: SquareWindowDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create and retain the window delegate
        windowDelegate = SquareWindowDelegate()

        // Set all windows to floating level and square aspect ratio
        for window in NSApp.windows {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces]
            window.delegate = windowDelegate

            // Set initial square size
            if let screen = window.screen {
                let screenFrame = screen.visibleFrame
                let size = min(window.frame.width, window.frame.height, 400)
                let x = screenFrame.midX - size / 2
                let y = screenFrame.midY - size / 2
                window.setFrame(NSRect(x: x, y: y, width: size, height: size), display: true)
            }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Ensure windows stay floating when app becomes active
        for window in NSApp.windows {
            window.level = .floating
        }
    }
}

// Window delegate to maintain square aspect ratio
class SquareWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // Always return a square size based on the larger dimension
        let size = max(frameSize.width, frameSize.height)
        return NSSize(width: size, height: size)
    }
}