import AppKit

enum ReferenceLayout {
    static let initialSize = NSSize(width: 1280, height: 720)
    static let minimumSize = NSSize(width: 1000, height: 640)
    static let margin: CGFloat = 18
    static let gap: CGFloat = 12
    static let previewWidthRatio: CGFloat = 0.35

    static let background = NSColor(srgbRed: 0.018, green: 0.023, blue: 0.037, alpha: 1)
    static let panel = NSColor(srgbRed: 0.055, green: 0.073, blue: 0.11, alpha: 1)
    static let panelBorder = NSColor(srgbRed: 0.18, green: 0.22, blue: 0.31, alpha: 1)
    static let text = NSColor(srgbRed: 0.94, green: 0.95, blue: 0.99, alpha: 1)
    static let muted = NSColor(srgbRed: 0.62, green: 0.67, blue: 0.78, alpha: 1)
    static let accent = NSColor(srgbRed: 0.42, green: 0.30, blue: 0.98, alpha: 1)
}

final class DarkPanel: NSView {
    override func makeBackingLayer() -> CALayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            NSColor(srgbRed: 0.085, green: 0.108, blue: 0.16, alpha: 1).cgColor,
            ReferenceLayout.panel.cgColor,
            NSColor(srgbRed: 0.038, green: 0.052, blue: 0.08, alpha: 1).cgColor
        ]
        gradient.locations = [0, 0.55, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 1)
        gradient.endPoint = CGPoint(x: 0.5, y: 0)
        return gradient
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.borderWidth = 1
        layer?.borderColor = ReferenceLayout.panelBorder.cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.28
        layer?.shadowRadius = 8
        layer?.shadowOffset = CGSize(width: 0, height: -3)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
