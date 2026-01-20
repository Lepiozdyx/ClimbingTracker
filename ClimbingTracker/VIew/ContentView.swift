//
//  ContentView.swift
//  ClimbingTracker
//
//  Created by Алексей Авер on 25.12.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var service = StateService()
        
    var body: some View {
        Group {
            switch service.appState {
            case .request:
                StartView()
                
            case .support:
                if let url = service.networkManager.petURL {
                    WKWebViewManager(
                        url: url,
                        webManager: service.networkManager
                    )
                } else {
                    WKWebViewManager(
                        url: NetworkService.initURL,
                        webManager: service.networkManager
                    )
                }
                
            case .loading:
                Root()
                    .preferredColorScheme(.dark)
            }
        }
        .onAppear {
            service.stateRequest()
        }
    }
}

#Preview {
    ContentView()
        
}

