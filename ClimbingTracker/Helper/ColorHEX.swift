import Foundation

import SwiftUI

extension Color {
    
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        
        func byte(from hexPair: Substring) -> CGFloat {
            let value = UInt8(hexPair, radix: 16) ?? 0
            return CGFloat(value) / 255.0
        }
        
        if cleaned.count == 6 {
            cleaned = "FF" + cleaned
        }
        
        guard cleaned.count == 8 else {
            self = Color.red
            return
        }
        
        let a = cleaned.prefix(2)
        let r = cleaned.dropFirst(2).prefix(2)
        let g = cleaned.dropFirst(4).prefix(2)
        let b = cleaned.dropFirst(6).prefix(2)
        
        self = Color(
            .sRGB,
            red: byte(from: r),
            green: byte(from: g),
            blue: byte(from: b),
            opacity: byte(from: a)
        )
    }
}
