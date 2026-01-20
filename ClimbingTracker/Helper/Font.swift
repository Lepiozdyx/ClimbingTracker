import Foundation
import SwiftUI
import UIKit

enum AppFont {

    enum Weight {
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case expandedHeavy

        fileprivate var uiWeight: UIFont.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy, .expandedHeavy: return .heavy
            }
        }
    }

    
    static func make(size: CGFloat, weight: Weight) -> Font {
        let baseUIFont = UIFont.systemFont(ofSize: size, weight: weight.uiWeight)

        if weight == .expandedHeavy {
            
            let widthValue: CGFloat = 0.35

            let descriptor = baseUIFont.fontDescriptor

            var traits = descriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any] ?? [:]

            traits[.width] = widthValue

            let expandedDescriptor = descriptor.addingAttributes([.traits: traits])

            let expandedUIFont = UIFont(descriptor: expandedDescriptor, size: size)

            return Font(expandedUIFont)
        }

        return Font(baseUIFont)
    }
}
