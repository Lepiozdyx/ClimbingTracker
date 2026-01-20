//
//  Root.swift
//  ClimbingTracker
//
//  Created by Алексей Авер on 26.12.2025.
//

import SwiftUI

struct Root: View {
    @StateObject private var store = ClimbingStore()
    var body: some View {
        NavigationStack {
            RootTabContainer()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    Root()
        .environmentObject(ClimbingStore())
}
