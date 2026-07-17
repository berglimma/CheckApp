//
//  ProfileView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

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
    @State private var alertMessage = "Dados atualizados."
    @State private var photoOwnerId: String = ""
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    
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
                                HStack {
                                    Text("Tipo de acesso")
                                        .font(AWTheme.caption(12))
                                        .foregroundStyle(AWTheme.textSecondary)
                                    Spacer()
                                    AWBadge(
                                        text: session.roleTitle,
                                        color: session.isAdmin ? AWTheme.warning : AWTheme.accent
                                    )
                                }
                                
                                Text(session.currentUser?.role.descricao ?? UserRole.normal.descricao)
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(AWTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
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
                        
                        if session.isAdmin {
                            AWSectionCard(title: "Administração") {
                                VStack(spacing: 10) {
                                    NavigationLink {
                                        UsersListView()
                                    } label: {
                                        legalRow(title: "Gerenciar equipe", systemImage: "person.3.fill")
                                    }
                                    .buttonStyle(.plain)
                                    
                                    NavigationLink {
                                        AutoWiseCadastro()
                                    } label: {
                                        legalRow(title: "Cadastrar funcionário", systemImage: "person.badge.plus")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        AWPrimaryButton(title: "Salvar alterações") {
                            if let user = session.currentUser {
                                user.name = name
                                user.phone = phone
                                try? context.save()
                            }
                            alertMessage = "Dados atualizados."
                            showAlert = true
                        }
                        
                        AWSectionCard(title: "Documentos e suporte") {
                            VStack(spacing: 10) {
                                Text("Tratamos CPF, telefone, e-mail, fotos e assinaturas apenas para operações de frota. Ao excluir a conta, esses dados operacionais locais também são apagados neste dispositivo.")
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(AWTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                NavigationLink {
                                    LegalDocumentsView(document: .privacy)
                                } label: {
                                    legalRow(title: "Política de Privacidade", systemImage: "hand.raised.fill")
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink {
                                    LegalDocumentsView(document: .terms)
                                } label: {
                                    legalRow(title: "Termos de Uso", systemImage: "doc.text.fill")
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink {
                                    LegalDocumentsView(document: .support)
                                } label: {
                                    legalRow(title: "Suporte", systemImage: "questionmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                
                                Link(destination: URL(string: "mailto:\(AppStoreLinks.supportEmail)?subject=Suporte%20Auto%20Wize")!) {
                                    legalRow(title: AppStoreLinks.supportEmail, systemImage: "envelope.fill")
                                }
                            }
                        }
                        
                        AWSectionCard(title: "Conta") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("A exclusão remove permanentemente sua conta, históricos, dados de clientes (incluindo CPF), fotos, assinaturas e reservas neste dispositivo.")
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(AWTheme.textSecondary)
                                
                                Button(role: .destructive) {
                                    showDeleteConfirm = true
                                } label: {
                                    HStack {
                                        if isDeleting {
                                            ProgressView()
                                                .tint(.white)
                                        }
                                        Text(isDeleting ? "Excluindo..." : "Excluir minha conta")
                                            .font(AWTheme.headline(16))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: AWTheme.fieldHeight)
                                    .background(AWTheme.danger)
                                    .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(isDeleting)
                            }
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
            Text(alertMessage)
        }
        .confirmationDialog(
            "Excluir conta?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Excluir permanentemente", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação não pode ser desfeita. Serão apagados: sua conta, históricos, CPF/dados de clientes, fotos, assinaturas e reservas neste aparelho.")
        }
    }
    
    private func legalRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(AWTheme.accent)
            Text(title)
                .font(AWTheme.headline(14))
                .foregroundStyle(AWTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AWTheme.textSecondary.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
    
    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            try await session.deleteAccount(context: context)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .environmentObject(SessionManager())
}
