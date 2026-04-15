import SwiftUI

struct MenuItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 30)
            Text(text)
                .font(.body)
                .fontWeight(.medium)
            Spacer()
        }
        .foregroundColor(.primary)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(alignment: .leading) {
        MenuItem(icon: "person.fill", text: "Perfil")
        MenuItem(icon: "gearshape.fill", text: "Configuración")
        MenuItem(icon: "star.fill", text: "Favoritos")
        MenuItem(icon: "questionmark.circle.fill", text: "Ayuda")
    }
    .padding()
}
