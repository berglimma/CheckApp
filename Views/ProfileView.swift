import SwiftUI
import SwiftData
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var profileImage: UIImage?
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var showAlert = false
    @State private var photoOwnerId: String = ""
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    AWScreenTitle(title: "Meu perfil", subtitle: "Foto e dados da conta")
                    
                    if session.currentUser != nil, !photoOwnerId.isEmpty {
                        AWSectionCard {
                            AWProfilePhotoPicker(ownerId: photoOwnerId, image: $profileImage)
                                .frame(maxWidth: .infinity)
                        }
                        
                        AWSectionCard(title: "Dados") {
                            VStack(spacing: 12) {
                                AWTextField(placeholder: "Nome", text: $name)
                                Text(session.currentUser?.email ?? "")
                                    .font(AWTheme.body(14))
                                    .foregroundStyle(AWTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                AWTextField(
                                    placeholder: "Telefone",
                                    text: $phone,
                                    keyboard: .phonePad,
                                    autocapitalization: .never
                                )
                            }
                        }
                        
                        AWPrimaryButton(title: "Salvar alterações") {
                            if let user = session.currentUser {
                                user.name = name
                                user.phone = phone
                                try? context.save()
                            }
                            showAlert = true
                        }
                        
                        AWSecondaryButton(title: "Voltar") { dismiss() }
                            .padding(.bottom, 28)
                    }
                }
                .awReadableWidth(AWLayout.formMaxWidth)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .onAppear {
            name = session.currentUser?.name ?? ""
            phone = session.currentUser?.phone ?? ""
            if let user = session.currentUser {
                session.ensurePhotoOwnerId(for: user, context: context)
                photoOwnerId = user.photoOwnerId
            }
            session.loadProfileImage(context: context)
            profileImage = session.profileImage
        }
        .onChange(of: profileImage) { _, newImage in
            session.updateProfileImage(newImage)
        }
        .alert("Perfil", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Dados atualizados.")
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .environmentObject(SessionManager())
}
