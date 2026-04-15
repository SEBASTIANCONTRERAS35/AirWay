//
//  MainTabView.swift
//  AcessNet
//
//  Created by BICHOTEE
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home
        case map
        case settings
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    AQIHomeView()
                case .map:
                    ContentView()
                case .settings:
                    SettingsView()
                }
            }
            .ignoresSafeArea()
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                title: "",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }

            TabBarButton(
                icon: "location.fill",
                title: "",
                isSelected: selectedTab == .map
            ) {
                selectedTab = .map
            }

            TabBarButton(
                icon: "gearshape.fill",
                title: "",
                isSelected: selectedTab == .settings
            ) {
                selectedTab = .settings
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(selectedTab == .map ? AnyShapeStyle(Color.clear) : AnyShapeStyle(.ultraThinMaterial))
                .shadow(color: selectedTab == .map ? .clear : .black.opacity(0.15), radius: 12, x: 0, y: -5)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color("AccentColor") : .white.opacity(0.5))
                    .frame(height: 28)

                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? Color("AccentColor") : .white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}

