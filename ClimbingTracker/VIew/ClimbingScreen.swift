import SwiftUI

struct ClimbingScreen<Content: View>: View {
    let title: String
    let showsBackButton: Bool
    let onBackTap: (() -> Void)?
    let content: Content

    init(
        title: String,
        showsBackButton: Bool,
        onBackTap: (() -> Void)?,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showsBackButton = showsBackButton
        self.onBackTap = onBackTap
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            let barContentHeight: CGFloat = 56
            let navBarHeight = topInset + barContentHeight

            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                content
                    .padding(.top, navBarHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                ClimbingNavBarDynamic(
                    title: title,
                    showsBackButton: showsBackButton,
                    onBackTap: onBackTap,
                    topInset: topInset,
                    barContentHeight: barContentHeight
                )
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

private struct ClimbingNavBarDynamic: View {
    let title: String
    let showsBackButton: Bool
    let onBackTap: (() -> Void)?
    let topInset: CGFloat
    let barContentHeight: CGFloat

    private var underlineWidth: CGFloat {
        UIScreen.main.bounds.width * UIConstants.navBarUnderlineWidthRatio
    }

    var body: some View {
        let totalHeight = topInset + barContentHeight

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
                    .frame(width: underlineWidth, height: UIConstants.navBarUnderlineHeight)
                    .cornerRadius(3)
            }
            .padding(.top, topInset)
            .padding(.bottom, 14)
        }
        .frame(height: totalHeight)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
    }
}
