//
//  AppConstants.swift
//  AcessNet
//
//  Constantes globales de la aplicación
//

import SwiftUI
import UIKit

// MARK: - Layout Constants

struct AppConstants {

    // MARK: - Tab Bar

    /// Altura total del Enhanced Tab Bar incluyendo todos los paddings y safe area
    /// Cálculo: 16 (top padding) + 56 (button height) + 16 (bottom padding) + 8 (bottom margin) + 34 (safe area aprox)
    static let enhancedTabBarHeight: CGFloat = 130

    /// Altura del Enhanced Tab Bar sin safe area
    /// Cálculo: 16 (top padding) + 56 (button height) + 16 (bottom padding) + 8 (bottom margin)
    static let enhancedTabBarHeightWithoutSafeArea: CGFloat = 96

    /// Safe area top actual del dispositivo
    static var safeAreaTop: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        return window?.safeAreaInsets.top ?? 0
    }

    /// Safe area bottom promedio (varía por dispositivo)
    static var safeAreaBottom: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        return window?.safeAreaInsets.bottom ?? 34
    }

    /// Altura total del tab bar considerando safe area real del dispositivo
    static var enhancedTabBarTotalHeight: CGFloat {
        return enhancedTabBarHeightWithoutSafeArea + safeAreaBottom
    }

    // MARK: - Common Spacing

    /// Padding estándar para contenido sobre el tab bar
    static var contentBottomPadding: CGFloat {
        return enhancedTabBarTotalHeight + 12 // Tab bar + margen
    }

    /// Padding para elementos flotantes (como botones) sobre el tab bar
    static var floatingElementBottomPadding: CGFloat {
        return enhancedTabBarTotalHeight + 20 // Tab bar + margen más grande
    }
}

// MARK: - View Extension

extension View {
    /// Aplica padding bottom para evitar que el contenido se solape con el Enhanced Tab Bar
    func avoidTabBar(extraPadding: CGFloat = 12) -> some View {
        self.padding(.bottom, AppConstants.enhancedTabBarTotalHeight + extraPadding)
    }

    /// Aplica padding bottom para elementos flotantes sobre el tab bar
    func aboveTabBar(extraPadding: CGFloat = 20) -> some View {
        self.padding(.bottom, AppConstants.enhancedTabBarTotalHeight + extraPadding)
    }
}
