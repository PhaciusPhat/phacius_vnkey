import AppKit
import CoreGraphics

/// Generates the menu bar status item icon programmatically.
/// Produces a template image so macOS automatically inverts it
/// for dark/light menu bar modes and the selected (highlighted) state.
enum MenuBarIcon {
    /// Returns a 22×22pt template image with the "VN" monogram.
    static func make(enabled: Bool) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size, flipped: false) { rect in
            drawIcon(in: rect, enabled: enabled)
            return true
        }
        // Template = macOS recolours it automatically for dark/light menu bar.
        image.isTemplate = true
        return image
    }

    private static func drawIcon(in rect: NSRect, enabled: Bool) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let w = rect.width
        let h = rect.height

        // Use black; template mode makes macOS handle colour inversion.
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 1))

        if enabled {
            drawVN(ctx: ctx, rect: rect)
        } else {
            // Disabled: draw VN with a diagonal strikethrough.
            ctx.setAlpha(0.35)
            drawVN(ctx: ctx, rect: rect)
            ctx.setAlpha(1.0)
            drawStrike(ctx: ctx, rect: rect)
        }
    }

    /// Draw the "VN" letterform using bezier paths so it stays crisp at all sizes.
    private static func drawVN(ctx: CGContext, rect: NSRect) {
        let w = rect.width
        let h = rect.height

        // Scale factors so the design fits any rect.
        let sx: CGFloat = w / 22
        let sy: CGFloat = h / 22

        // ── V  (left half) ─────────────────────────────────────────────
        // V: two angled strokes meeting at a point, occupying x 1…10, y 5…17
        let vPath = CGMutablePath()
        let stroke: CGFloat = 1.6 * sx

        // Left arm of V: top-left (1,5) → midpoint (5.5, 16)
        // Right arm of V: midpoint (5.5, 16) → (10, 5)
        // Drawn as a filled chevron shape.
        let vL  = CGPoint(x: 1   * sx, y: 16 * sy)  // top-left  (flipped: y=16 is near top in CG)
        let vM  = CGPoint(x: 5.5 * sx, y: 5  * sy)  // bottom tip
        let vR  = CGPoint(x: 10  * sx, y: 16 * sy)  // top-right

        vPath.move(to: vL)
        vPath.addLine(to: CGPoint(x: vL.x + stroke * 1.1, y: vL.y))
        vPath.addLine(to: CGPoint(x: vM.x + stroke * 0.6, y: vM.y + stroke * 1.2))
        vPath.addLine(to: CGPoint(x: vR.x, y: vR.y))
        vPath.addLine(to: CGPoint(x: vR.x - stroke * 1.1, y: vR.y))
        vPath.addLine(to: CGPoint(x: vM.x, y: vM.y + stroke * 0.5))
        vPath.closeSubpath()

        ctx.addPath(vPath)
        ctx.fillPath()

        // ── N  (right half) ────────────────────────────────────────────
        // N: two verticals + a diagonal, occupying x 12…21, y 5…17
        let nX1: CGFloat = 12 * sx   // left vertical x
        let nX2: CGFloat = 21 * sx   // right vertical x
        let nTop: CGFloat = 16 * sy  // top y (CG y-up)
        let nBot: CGFloat = 5  * sy  // bottom y

        // Left vertical bar
        let nLeft = CGRect(x: nX1, y: nBot, width: stroke * 1.2, height: nTop - nBot)
        ctx.fill(nLeft)

        // Right vertical bar
        let nRight = CGRect(x: nX2 - stroke * 1.2, y: nBot, width: stroke * 1.2, height: nTop - nBot)
        ctx.fill(nRight)

        // Diagonal stroke: top-left → bottom-right
        let diagPath = CGMutablePath()
        let diagTL = CGPoint(x: nX1,               y: nTop)
        let diagBR = CGPoint(x: nX2 - stroke * 1.2, y: nBot)

        // Compute the perpendicular offset for stroke thickness.
        let dx = diagBR.x - diagTL.x
        let dy = diagBR.y - diagTL.y
        let len = sqrt(dx*dx + dy*dy)
        let px = (-dy / len) * stroke * 0.9  // perpendicular x
        let py = ( dx / len) * stroke * 0.9  // perpendicular y

        diagPath.move(to: CGPoint(x: diagTL.x + px, y: diagTL.y + py))
        diagPath.addLine(to: CGPoint(x: diagTL.x - px, y: diagTL.y - py))
        diagPath.addLine(to: CGPoint(x: diagBR.x - px + stroke * 1.2, y: diagBR.y - py))
        diagPath.addLine(to: CGPoint(x: diagBR.x + px + stroke * 1.2, y: diagBR.y + py))
        diagPath.closeSubpath()
        ctx.addPath(diagPath)
        ctx.fillPath()
    }

    /// A single diagonal line through the icon indicating disabled state.
    private static func drawStrike(ctx: CGContext, rect: NSRect) {
        let w = rect.width
        let h = rect.height
        ctx.setLineWidth(1.5)
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: w * 0.15, y: h * 0.2))
        ctx.addLine(to: CGPoint(x: w * 0.85, y: h * 0.8))
        ctx.strokePath()
    }
}
