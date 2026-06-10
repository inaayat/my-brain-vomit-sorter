import AppKit
import SwiftUI
import CoreText

enum FontLoader {
    static func registerFonts() {
        let fontNames = ["Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold"]
        guard let bundle = findResourceBundle() else { return }
        for name in fontNames {
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static func findResourceBundle() -> Bundle? {
        let bundleName = "MyMind_MyMind.bundle"

        // Check next to the executable
        if let execURL = Bundle.main.executableURL {
            let adjacent = execURL.deletingLastPathComponent().appendingPathComponent(bundleName)
            if let b = Bundle(url: adjacent) { return b }
        }

        // Check inside the main bundle
        let mainBundlePath = Bundle.main.bundleURL.appendingPathComponent(bundleName)
        if let b = Bundle(path: mainBundlePath.path) { return b }

        // Check in Resources inside the app bundle
        if let resourceURL = Bundle.main.resourceURL {
            let resourcePath = resourceURL.appendingPathComponent(bundleName)
            if let b = Bundle(url: resourcePath) { return b }
        }

        return nil
    }
}

extension Font {
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold: name = "Inter-Bold"
        case .semibold: name = "Inter-SemiBold"
        case .medium: name = "Inter-Medium"
        default: name = "Inter-Regular"
        }
        return .custom(name, size: size)
    }
}
