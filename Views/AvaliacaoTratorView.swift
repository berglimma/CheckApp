//
//  AvaliacaoTratorView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData

struct AvaliacaoTratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var form = AvaliacaoTrator()
    @State private var condicao: CondicaoGeral = .boa
    @StateObject private var signaturePad = SignaturePadController()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var saved = false
    @State private var notifyPayload: MessageComposePayload?
    
    private var isFormValid: Bool {
        !form.cliente.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.funcionario.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.identificacao.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.modelo.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.horimetro.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.horaRegistro.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    AWScreenTitle(
                        title: "Avaliação de Trator",
                        subtitle: "Inspeção de equipamento pesado"
                    )
                    
                    AWSectionCard(title: "Cliente e responsável") {
                        VStack(spacing: 12) {
                            AWTextField(placeholder: "Cliente / proprietário", text: $form.cliente)
                            AWTextField(
                                placeholder: "CPF / Documento",
                                text: $form.documentoCliente,
                                keyboard: .numberPad,
                                autocapitalization: .never
                            )
                            .onChange(of: form.documentoCliente) { _, novoValor in
                                let formatado = DocumentFormatter.cpf(novoValor)
                                if formatado != novoValor {
                                    form.documentoCliente = formatado
                                }
                            }
                            AWTextField(
                                placeholder: "Telefone (SMS / iMessage)",
                                text: $form.telefoneCliente,
                                keyboard: .phonePad,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "E-mail do cliente (avisos vinculados)",
                                text: $form.emailCliente,
                                keyboard: .emailAddress,
                                autocapitalization: .never
                            )
                            Text("A avaliação será notificada ao telefone e e-mail do cliente.")
                                .font(AWTheme.caption(11))
                                .foregroundStyle(AWTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            AWFuncionarioPicker(
                                funcionario: $form.funcionario,
                                title: "Avaliador / funcionário"
                            )
                            AWDateField(title: "Data", date: $form.dataRegistro)
                            AWTextField(
                                placeholder: "Hora (HH:mm)",
                                text: $form.horaRegistro,
                                keyboard: .numbersAndPunctuation,
                                autocapitalization: .never
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Equipamento") {
                        VStack(spacing: 12) {
                            AWTextField(placeholder: "Identificação / frota", text: $form.identificacao)
                            AWBrandModelPicker(
                                marca: $form.marca,
                                modelo: $form.modelo,
                                kind: .tractor,
                                title: "Marca e modelo do trator"
                            )
                            AWTextField(placeholder: "Nº de série", text: $form.serie)
                            AWTextField(
                                placeholder: "Horímetro",
                                text: $form.horimetro,
                                keyboard: .decimalPad,
                                autocapitalization: .never
                            )
                            AWTextField(placeholder: "Local da avaliação", text: $form.localAvaliacao)
                        }
                    }
                    
                    AWSectionCard(title: "Condição geral") {
                        VStack(spacing: 12) {
                            AWPickerField(
                                title: "Estado geral",
                                selection: $condicao,
                                options: CondicaoGeral.allCases
                            )
                            Toggle("Aprovado para uso", isOn: $form.aprovadoParaUso)
                                .tint(AWTheme.accent)
                                .font(AWTheme.body(15))
                        }
                    }
                    
                    AWSectionCard(title: "Itens de inspeção") {
                        AWInspectionList(items: $form.itensInspecao)
                    }
                    
                    AWSectionCard(title: "Recomendações") {
                        AWNotesEditor(
                            text: $form.recomendacoes,
                            placeholder: "Manutenções sugeridas, peças a trocar..."
                        )
                    }
                    
                    AWSectionCard(title: "Observações") {
                        AWNotesEditor(text: $form.observacoes)
                    }
                    
                    AWSectionCard {
                        AWPhotoGallery(
                            ownerId: form.id.uuidString,
                            ownerType: .trator,
                            title: "Fotos do equipamento"
                        )
                    }
                    
                    AWSectionCard {
                        AWSignaturePad(controller: signaturePad)
                    }
                    
                    VStack(spacing: 10) {
                        AWPrimaryButton(title: "Salvar avaliação") { save() }
                        AWSecondaryButton(title: "Voltar") { dismiss() }
                    }
                    .padding(.bottom, 28)
                }
                .awReadableWidth(AWLayout.formMaxWidth)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .alert("Auto Wize", isPresented: $showAlert) {
            Button("OK") {
                if saved {
                    notifyPayload = MessageNotifyService.payloadTrator(
                        cliente: form.cliente,
                        telefone: form.telefoneCliente,
                        email: form.emailCliente,
                        marca: form.marca,
                        modelo: form.modelo,
                        identificacao: form.identificacao,
                        aprovado: form.aprovadoParaUso,
                        condicao: form.condicaoGeral
                    )
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(item: $notifyPayload) { payload in
            NotifyComposeSheet(payload: payload) {
                notifyPayload = nil
                dismiss()
            }
        }
    }
    
    private func save() {
        guard isFormValid else {
            alertMessage = "Preencha cliente, identificação, modelo, horímetro, funcionário e hora."
            showAlert = true
            saved = false
            return
        }
        
        form.condicaoGeral = condicao.rawValue
        
        if let data = try? JSONEncoder().encode(form) {
            UserDefaults.standard.set(data, forKey: "avaliacaoTrator_\(form.id.uuidString)")
        }
        
        let signatureImage = SignatureCapture.image(from: signaturePad)
        
        var snapshot = ReportSnapshot(
            id: form.id,
            tipo: "Trator",
            titulo: "Avaliação de Trator",
            cliente: form.cliente,
            placa: form.identificacao,
            funcionario: form.funcionario,
            dataRegistro: form.dataRegistro,
            horaRegistro: form.horaRegistro,
            campos: [
                "Documento": form.documentoCliente,
                "Telefone": form.telefoneCliente,
                "E-mail": form.emailCliente,
                "Marca": form.marca,
                "Modelo": form.modelo,
                "Série": form.serie,
                "Horímetro": form.horimetro,
                "Local": form.localAvaliacao,
                "Condição": form.condicaoGeral,
                "Aprovado": form.aprovadoParaUso ? "Sim" : "Não",
                "Recomendações": form.recomendacoes
            ],
            observacoes: form.observacoes,
            ownerId: form.id.uuidString,
            itensInspecao: form.itensInspecao
        )
        snapshot.attachSignature(signatureImage)
        ReportRepository.save(context: context, snapshot: snapshot)
        
        alertMessage = form.aprovadoParaUso
            ? "Avaliação salva. Em seguida envie o aviso por SMS/iMessage e e-mail."
            : "Avaliação salva (NÃO aprovado). Em seguida envie o aviso vinculado ao e-mail."
        saved = true
        showAlert = true
    }
}

#Preview {
    NavigationStack { AvaliacaoTratorView() }
        .modelContainer(for: [CheckListHistorico.self], inMemory: true)
}
