//
//  BusinessToastView.swift
//  AcessNet
//
//  A lightweight toast for in-app feedback when Business mode is activated.
//

import SwiftUI

struct BusinessToastView: View {
    var message: String
    var icon: String = "storefront"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .imageScale(.medium)
            Text(message)
                .foregroundStyle(.white)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        .accessibilityLabel(Text(message))
    }
}

#Preview {
    ZStack(alignment: .top) {
        Color(.systemBackground)
        BusinessToastView(message: "Modo Business activado")
            .padding(.top, 40)
            .padding(.horizontal, 16)
    }
}
