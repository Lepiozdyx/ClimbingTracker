//
//  TabBar.swift
//  ClimbingTracker
//
//  Created by Алексей Авер on 25.12.2025.
//

import Foundation

import SwiftUI

struct TabBarButton: View {
    
    let item: TabItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                
                Image(isSelected ? item.asset.on : item.asset.off)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                
                Text(item.title)
                    .font(AppFont.make(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? .white : .gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(height: 68, alignment: .top)
        }
        .buttonStyle(.plain)
    }
}

struct CustomTabBar: View {
    
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack {
            ForEach(TabItem.allCases, id: \.self) { item in
                TabBarButton(
                    item: item,
                    isSelected: selectedTab == item,
                    onTap: {
                        selectedTab = item
                    }
                )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(UIConstants.navBarBackground)
    }
}

struct RootTabContainer: View {
    @State private var selectedTab: TabItem = .home
    @EnvironmentObject private var store: ClimbingStore
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .places:
                    PlacesView()
                case .calendar:
                    CalendarView()
                case .stats:
                    StatisticsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(store)
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home))
}
