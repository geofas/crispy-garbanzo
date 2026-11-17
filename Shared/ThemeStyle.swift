import SwiftUI
import UIKit
import NudgyKit

/// Colours and type for a theme, used by both the iPhone and the Watch app.
/// Basic leaves every value to the system, so it looks like a standard iOS app.
struct ThemeStyle {
    /// Forced light or dark appearance; nil follows the system.
    var colorScheme: ColorScheme?
    /// Screen background; nil keeps the system background.
    var background: Color?
    /// Background of list rows and cards; nil keeps the system grouped background.
    var surface: Color?
    var primaryText: Color
    var secondaryText: Color
    /// Buttons, start icons, the next nudge.
    var accent: Color
    /// Text and icons placed on the accent colour.
    var onAccent: Color
    /// Background for the highlighted "next" row on the session screen.
    var highlight: Color
    var destructive: Color
    /// Typeface for headings and the countdown; nil uses San Francisco.
    var displayFont: String?
    /// Typeface for all other text; nil uses San Francisco.
    var textFont: String?
    /// San Francisco design used when no custom typeface is set.
    var systemDesign: Font.Design

    static func of(_ theme: Theme) -> ThemeStyle {
        #if os(watchOS)
        return watch(theme)
        #else
        return phone(theme)
        #endif
    }

    /// Apple Watch screens are always dark, so both designed themes keep a black screen
    /// and differ in accent and row colour (design canvas, A2 and B2 Apple Watch boards).
    private static func watch(_ theme: Theme) -> ThemeStyle {
        switch theme {
        case .basic:
            var basic = phone(.basic)
            basic.highlight = .primary // used as text colour on the Watch
            return basic
        case .quietSignal:
            return ThemeStyle(
                colorScheme: nil, background: nil, surface: Color(hex: 0x1A2236),
                primaryText: Color(hex: 0xE9EDF5), secondaryText: Color(hex: 0xAEB8CC),
                accent: Color(hex: 0xF2A93B), onAccent: Color(hex: 0x0E1320),
                highlight: Color(hex: 0xF2A93B),
                destructive: Color(hex: 0xFF8F80),
                displayFont: "Space Grotesk", textFont: nil, systemDesign: .default
            )
        case .friendlyTap:
            return ThemeStyle(
                colorScheme: nil, background: nil, surface: Color(hex: 0x231E30),
                primaryText: .white, secondaryText: Color(hex: 0xC9C3D6),
                accent: Color(hex: 0xB5ABFF), onAccent: Color(hex: 0x251A33),
                highlight: Color(hex: 0xF5B83D),
                destructive: Color(hex: 0xFF9B91),
                displayFont: "Figtree", textFont: "Figtree", systemDesign: .default
            )
        }
    }

    private static func phone(_ theme: Theme) -> ThemeStyle {
        switch theme {
        case .basic:
            return ThemeStyle(
                colorScheme: nil, background: nil, surface: nil,
                primaryText: .primary, secondaryText: .secondary,
                accent: .accentColor, onAccent: .white,
                highlight: Color.accentColor.opacity(0.12),
                destructive: .red,
                displayFont: nil, textFont: nil, systemDesign: .rounded
            )
        case .quietSignal:
            // Design canvas "A2 · Product: native and buildable".
            return ThemeStyle(
                colorScheme: .dark,
                background: Color(hex: 0x0E1320), surface: Color(hex: 0x161D2E),
                primaryText: Color(hex: 0xE9EDF5), secondaryText: Color(hex: 0xAEB8CC),
                accent: Color(hex: 0xF2A93B), onAccent: Color(hex: 0x0E1320),
                highlight: Color(hex: 0xF2A93B).opacity(0.16),
                destructive: Color(hex: 0xFF8F80),
                displayFont: "Space Grotesk", textFont: nil, systemDesign: .default
            )
        case .friendlyTap:
            // Design canvas "B2 · Product: friendly but grown-up".
            return ThemeStyle(
                colorScheme: .light,
                background: Color(hex: 0xF6F4F8), surface: .white,
                primaryText: Color(hex: 0x251A33), secondaryText: Color(hex: 0x5F5470),
                accent: Color(hex: 0x5140C9), onAccent: .white,
                highlight: Color(hex: 0xFFF1CF),
                destructive: Color(hex: 0xA3241B),
                displayFont: "Figtree", textFont: "Figtree", systemDesign: .default
            )
        }
    }

    /// Heading or countdown type at a fixed size.
    func display(_ size: CGFloat, weight: UIFont.Weight = .semibold) -> Font {
        if let displayFont { return Self.custom(displayFont, size: size, weight: weight, scaledLike: nil) }
        return .system(size: size, weight: Self.swiftUIWeight(weight), design: systemDesign)
    }

    /// Body type that follows Dynamic Type.
    func text(_ style: Font.TextStyle, weight: UIFont.Weight = .regular) -> Font {
        if let textFont {
            return Self.custom(textFont, size: Self.baseSize(style), weight: weight, scaledLike: Self.uiTextStyle(style))
        }
        return .system(style, design: .default, weight: Self.swiftUIWeight(weight))
    }

    /// A bundled variable typeface by family name and weight. If the family is missing,
    /// UIKit falls back to the system font, so text never disappears.
    private static func custom(_ family: String, size: CGFloat, weight: UIFont.Weight, scaledLike textStyle: UIFont.TextStyle?) -> Font {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        var font = UIFont(descriptor: descriptor, size: size)
        if let textStyle { font = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font) }
        return Font(font)
    }

    private static func swiftUIWeight(_ weight: UIFont.Weight) -> Font.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }

    private static func uiTextStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle:
            #if os(watchOS)
            return .title1
            #else
            return .largeTitle
            #endif
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }

    private static func baseSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline, .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        default: return 17
        }
    }
}

extension Color {
    /// A colour from a 0xRRGGBB value.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

private struct ThemeStyleKey: EnvironmentKey {
    static let defaultValue = ThemeStyle.of(.basic)
}

extension EnvironmentValues {
    var themeStyle: ThemeStyle {
        get { self[ThemeStyleKey.self] }
        set { self[ThemeStyleKey.self] = newValue }
    }
}

extension View {
    /// Applies a theme to a whole screen tree: appearance, accent, text colour and background.
    func themed(_ theme: Theme) -> some View {
        let style = ThemeStyle.of(theme)
        return self
            .environment(\.themeStyle, style)
            .tint(style.accent)
            .font(style.text(.body))
            .preferredColorScheme(style.colorScheme)
    }

    /// Replaces the list background with the theme's, when the theme sets one.
    @ViewBuilder
    func themedListBackground(_ style: ThemeStyle) -> some View {
        if let background = style.background {
            self.scrollContentBackground(.hidden).background(background)
        } else {
            self
        }
    }

    /// Row background for themed lists; Basic keeps the system row background.
    @ViewBuilder
    func themedRow(_ style: ThemeStyle) -> some View {
        if let surface = style.surface {
            self.listRowBackground(surface)
        } else {
            self
        }
    }
}
