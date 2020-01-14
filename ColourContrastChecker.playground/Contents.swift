import UIKit

// Colour constrast checker for accessibility

extension UIColor {
    
    func relativeLuminance() -> Double? {
        guard let rgb = rgb() else { return nil }
        let rs: Double = Double(rgb.0)
        let gs: Double = Double(rgb.1)
        let bs: Double = Double(rgb.2)
        let r: Double = rs <= 0.03928 ? rs/12.92 : pow(((rs + 0.055)/1.055),2.4)
        let g: Double = gs <= 0.03928 ? gs/12.92 : pow(((gs + 0.055)/1.055),2.4)
        let b: Double = bs <= 0.03928 ? bs/12.92 : pow(((bs + 0.055)/1.055),2.4)
        return (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    }
    
    private func rgb() -> (CGFloat,CGFloat,CGFloat)? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            return (fRed, fGreen, fBlue)
        } else {
            return nil
        }
    }
}

// Test colour pairs

struct ColourPair {
    
    let primary: UIColor
    let secondary: UIColor
    
    // Large is bold 14pt+ or 18pt+
    enum AccessibilityLevel {
        case aa(large: Bool = false)
        case aaa(large: Bool = false)
    }
    
    // Cannot determine for clear colours so will return nil
    func isAccessible(at accessibilityLevel: AccessibilityLevel) -> Bool? {
        if primary == .clear || secondary == .clear { return nil }
        switch accessibilityLevel {
        case .aa(let large):  return large ?
            contrastRatio() > 3 :
            contrastRatio() > 4.5
        case .aaa(let large): return large ?
            contrastRatio() > 4.5 :
            contrastRatio() > 7
        }
    }
    
    func contrastRatio() -> Double {
        guard let a = primary.relativeLuminance(), let b = secondary.relativeLuminance() else { return 0 }
        let l1 = min(a, b)
        let l2 = max(a, b)
        return (l2 + 0.05)/(l1 + 0.05)
    }
}

// UIKit extensions
// Passes back nil if colours are not set or are clear, as cannot be determined

extension UILabel {
    
    func isAccessible(at accessibilityLevel: ColourPair.AccessibilityLevel) -> Bool? {
        guard let backgroundColor = backgroundColor else { return nil }
        let pair = ColourPair(primary: textColor, secondary: backgroundColor)
        return pair.isAccessible(at: accessibilityLevel)
    }
}

extension UIButton {
    
    func isAccessible(at accessibilityLevel: ColourPair.AccessibilityLevel, for state: UIControl.State) -> Bool? {
        guard let backgroundColor = backgroundColor, let titleColor = titleColor(for: state) else { return nil }
        let pair = ColourPair(primary: titleColor, secondary: backgroundColor)
        return pair.isAccessible(at: accessibilityLevel)
    }
}


// Usage:

let label = UILabel()
label.textColor = .blue
label.backgroundColor = .green
label.isAccessible(at: .aa())               // true
label.isAccessible(at: .aaa(large: true))   // false

let button = UIButton()
button.setTitleColor(.black, for: .normal)
button.setTitleColor(.white, for: .disabled)
button.backgroundColor = .white
button.isAccessible(at: .aa(), for: .normal)    // true
button.isAccessible(at: .aa(), for: .selected)  // true
button.isAccessible(at: .aa(), for: .disabled)  // false
