import Foundation

import SwiftUI

struct BackButtonView: View {
    
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(.backButton)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

struct ClimbingNavBar: View {
    let title: String
    let showsBackButton: Bool
    let onBackTap: (() -> Void)?

    private var underlineWidth: CGFloat {
        UIScreen.main.bounds.width * UIConstants.navBarUnderlineWidthRatio
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            let extraTopPadding: CGFloat = 16
            let barContentHeight: CGFloat = 56
            let totalHeight = topInset + extraTopPadding + barContentHeight

            ZStack {
                UIConstants.navBarBackground

                VStack(spacing: 10) {
                    Spacer(minLength: 0)

                    ZStack {
                        Text(title)
                            .font(AppFont.make(size: 24, weight: .expandedHeavy))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if showsBackButton {
                            HStack {
                                BackButtonView { onBackTap?() }
                                Spacer()
                            }
                            .padding(.leading, 20)
                        }
                    }

                    Rectangle()
                        .fill(UIConstants.navBarAccent)
                        .frame(
                            width: underlineWidth,
                            height: UIConstants.navBarUnderlineHeight
                        )
                        .cornerRadius(3)
                }
                .padding(.top, topInset + extraTopPadding)
                .padding(.bottom, 14)
            }
            .frame(height: totalHeight, alignment: .top)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)
        }
        .frame(height: 1)
    }
}
