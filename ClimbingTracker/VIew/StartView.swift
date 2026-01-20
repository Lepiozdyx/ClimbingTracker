import SwiftUI

struct StartView: View {
    
    var body: some View {
        ZStack {
            Image(.grees)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Text("Loading...")
                    .font(AppFont.make(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                
               ProgressView()
                    .scaleEffect(1.5)
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    StartView()
}
