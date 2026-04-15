import SwiftUI

// MARK: - Design System Colors
// Expose a Color asset named "primary2" as a ShapeStyle so `.fill(.primary2)` works.
extension ShapeStyle where Self == Color {
    static var primary2: Color { Color("primary2") }
}

struct Onboarding: View {
    @State public var mostrarSheet = true
        
    var body: some View {
        VStack {
        }
        .sheet(isPresented: $mostrarSheet) {
            MiBottomSheet()
                .presentationDragIndicator(.visible)
        }
    }
}

struct MiBottomSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var emailOrPhone: String = ""
    @State private var isAccepted: Bool = false
    
    var body: some View {
        ZStack {
            // Fondo glass
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(.ultraThinMaterial) // efecto glass de iOS
                .ignoresSafeArea()
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 0) {
                // Header buttons
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // acción ayuda
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "x.circle.fill")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Contenido principal
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        welcomeTitle
                        emailPhoneField
                        termsCheckbox
                        continueButton
                        separatorView
                        socialLoginButtons
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Componentes
    private var welcomeTitle: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Welcome to")
                .font(.custom("HarmonyOS_Sans_Regular", size: 25))
            
            Text("AccessNet")
                .font(.custom("HarmonyOS_Sans_Bold", size: 32))
                .padding(.leading, 5)
            
            Spacer()
        }
    }
    
    private var emailPhoneField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email or Phone Number")
                .font(.custom("HarmonyOS_Sans_Medium", size: 16))
                .foregroundColor(.secondary)
            
            TextField("Enter your email or phone", text: $emailOrPhone)
                .font(.custom("HarmonyOS_Sans_Regular", size: 18))
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial) // también glass
                )
        }
    }
    
    private var separatorView: some View {
        HStack {
            VStack { Divider() }
            Text("or")
                .font(.custom("HarmonyOS_Sans_Regular", size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
            VStack { Divider() }
        }
        .padding(.vertical, 10)
    }
    
    private var socialLoginButtons: some View {
        VStack(spacing: 12) {
            Button(action: { print("Continue with Google") }) {
                HStack {
                    Image("Google Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Spacer()
                    Text("Continue with Google")
                        .font(.custom("HarmonyOS_Sans_Medium", size: 16))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            }
            
            Button(action: { print("Continue with Apple") }) {
                HStack {
                    Image(systemName: "applelogo")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Continue with Apple")
                        .font(.custom("HarmonyOS_Sans_Medium", size: 16))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            }
        }
    }
    
    private var termsCheckbox: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { isAccepted.toggle() }) {
                if isAccepted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.primary2))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            termsText
        }
        .font(.custom("HarmonyOS_Sans_Regular", size: 14))
        .foregroundColor(.secondary)
    }
    
    private var termsText: some View {
        Text("By creating an account, I agree to AccessNet's ")
        + underlinedText("Terms of service", action: { print("Abrir términos") })
        + Text(" and ")
        + underlinedText("Privacy Notice", action: { print("Abrir privacidad") })
        + Text(".")
    }
    
    private func underlinedText(_ text: String, action: @escaping () -> Void) -> Text {
        Text(text)
            .underline()
            .foregroundColor(.blue)
    }
    
    private var continueButton: some View {
        Button(action: { if isAccepted { dismiss() } }) {
            Text("Continue")
                .font(.custom("HarmonyOS_Sans_Bold", size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isAccepted ? .primary2 : .gray)
                )
        }
        .disabled(!isAccepted)
    }
}

#Preview {
    Onboarding()
}
