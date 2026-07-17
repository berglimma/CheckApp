//
//  ChecklistDevolucaoView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import PencilKit
import SwiftData

struct ChecklistDevolucaoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = ChecklistDevolucaoViewModel()
    @State private var canvasView = PKCanvasView()
    @State private var activeAlert: AlertType?
    @State private var notifyPayload: MessageComposePayload?
    
    enum AlertType: Identifiable {
        case saveSuccess, validationError
        
        var id: Int {
            switch self {
            case .saveSuccess: return 0
            case .validationError: return 1
            }
        }
    }
    
    private var isFormValid: Bool {
        let c = viewModel.checklistDevolucao
        return !c.placa.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.funcionario.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.horaRegistro.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.cliente.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.kmRetorno.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    AWScreenTitle(
                        title: "Checklist de Devolução",
                        subtitle: "Documente o retorno do veículo"
                    )
                    
                    AWSectionCard(title: "Cliente") {
                        VStack(spacing: 12) {
                            AWTextField(placeholder: "Nome do cliente", text: $viewModel.checklistDevolucao.cliente)
                            AWTextField(
                                placeholder: "CPF / Documento",
                                text: $viewModel.checklistDevolucao.documentoCliente,
                                keyboard: .numbersAndPunctuation,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "Telefone (SMS / iMessage)",
                                text: $viewModel.checklistDevolucao.telefoneCliente,
                                keyboard: .phonePad,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "E-mail do cliente",
                                text: $viewModel.checklistDevolucao.emailCliente,
                                keyboard: .emailAddress,
                                autocapitalization: .never
                            )
                            Text("Avisos de movimentação serão enviados ao telefone e e-mail.")
                                .font(AWTheme.caption(11))
                                .foregroundStyle(AWTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    AWSectionCard(title: "Veículo") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "Placa",
                                text: $viewModel.checklistDevolucao.placa,
                                autocapitalization: .characters
                            )
                            AWBrandModelPicker(
                                marca: $viewModel.checklistDevolucao.marca,
                                modelo: $viewModel.checklistDevolucao.modelo,
                                kind: .car
                            )
                            AWTextField(placeholder: "Cor", text: $viewModel.checklistDevolucao.cor)
                            AWTextField(
                                placeholder: "KM na saída",
                                text: $viewModel.checklistDevolucao.kmSaida,
                                keyboard: .numberPad,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "KM no retorno",
                                text: $viewModel.checklistDevolucao.kmRetorno,
                                keyboard: .numberPad,
                                autocapitalization: .never
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Registro") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "Funcionário responsável",
                                text: $viewModel.checklistDevolucao.funcionario
                            )
                            AWDateField(title: "Data", date: $viewModel.checklistDevolucao.dataRegistro)
                            AWTextField(
                                placeholder: "Hora (HH:mm)",
                                text: $viewModel.checklistDevolucao.horaRegistro,
                                keyboard: .numbersAndPunctuation,
                                autocapitalization: .never
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Combustível e condição") {
                        VStack(spacing: 12) {
                            AWFuelSlider(
                                value: $viewModel.checklistDevolucao.combustivel,
                                labelProvider: viewModel.sliderLabel(for:)
                            )
                            AWPickerField(
                                title: "Condição geral",
                                selection: $viewModel.condicao,
                                options: CondicaoGeral.allCases
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Conferência de itens") {
                        AWInspectionList(items: $viewModel.itensInspecao)
                    }
                    
                    AWSectionCard(title: "Avarias no retorno") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Possui avarias novas", isOn: $viewModel.checklistDevolucao.possuiAvarias)
                                .tint(AWTheme.accent)
                                .font(AWTheme.body(15))
                            
                            if viewModel.checklistDevolucao.possuiAvarias {
                                AWNotesEditor(
                                    text: $viewModel.checklistDevolucao.descricaoAvarias,
                                    placeholder: "Descreva as avarias encontradas..."
                                )
                            }
                        }
                    }
                    
                    AWSectionCard(title: "Observações") {
                        AWNotesEditor(text: $viewModel.checklistDevolucao.observacoes)
                    }
                    
                    AWSectionCard {
                        AWPhotoGallery(
                            ownerId: viewModel.checklistDevolucao.id.uuidString,
                            ownerType: .devolucao,
                            title: "Fotos da devolução"
                        )
                    }
                    
                    AWSectionCard {
                        AWSignaturePad(canvasView: $canvasView, onClear: clearCanvas)
                    }
                    
                    VStack(spacing: 10) {
                        AWPrimaryButton(title: "Salvar checklist") { saveChecklist() }
                        AWSecondaryButton(title: "Voltar") { dismiss() }
                    }
                }
                .awReadableWidth(AWLayout.formMaxWidth)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .saveSuccess:
                return Alert(
                    title: Text("Sucesso"),
                    message: Text("Devolução salva. Em seguida envie o aviso por SMS/iMessage e e-mail ao cliente."),
                    dismissButton: .default(Text("OK")) {
                        let c = viewModel.checklistDevolucao
                        notifyPayload = MessageNotifyService.payloadDevolucao(
                            cliente: c.cliente,
                            telefone: c.telefoneCliente,
                            email: c.emailCliente,
                            placa: c.placa,
                            marca: c.marca,
                            modelo: c.modelo,
                            kmRetorno: c.kmRetorno,
                            possuiAvarias: c.possuiAvarias
                        )
                    }
                )
            case .validationError:
                return Alert(title: Text("Atenção"), message: Text("Preencha cliente, placa, KM retorno, funcionário e hora."), dismissButton: .default(Text("OK")))
            }
        }
        .sheet(item: $notifyPayload) { payload in
            NotifyComposeSheet(payload: payload) {
                notifyPayload = nil
                dismiss()
            }
        }
    }
    
    private func saveChecklist() {
        guard isFormValid else {
            activeAlert = .validationError
            return
        }
        viewModel.checklistDevolucao.assinaturaData = canvasView.drawing.dataRepresentation()
        viewModel.salvarChecklistDevolucao(context: context)
        
        let c = viewModel.checklistDevolucao
        let signatureImage = SignatureCapture.image(from: canvasView.drawing)
        
        var snapshot = ReportSnapshot(
            id: c.id,
            tipo: "Devolução",
            titulo: "Checklist de Devolução",
            cliente: c.cliente,
            placa: c.placa,
            funcionario: c.funcionario,
            dataRegistro: c.dataRegistro,
            horaRegistro: c.horaRegistro,
            campos: [
                "Documento": c.documentoCliente,
                "Telefone": c.telefoneCliente,
                "E-mail": c.emailCliente,
                "Marca": c.marca,
                "Modelo": c.modelo,
                "Cor": c.cor,
                "KM saída": c.kmSaida,
                "KM retorno": c.kmRetorno,
                "Combustível": viewModel.sliderLabel(for: c.combustivel),
                "Condição": c.condicaoGeral,
                "Possui avarias": c.possuiAvarias ? "Sim" : "Não",
                "Avarias": c.descricaoAvarias
            ],
            observacoes: c.observacoes,
            ownerId: c.id.uuidString,
            itensInspecao: viewModel.itensInspecao
        )
        snapshot.attachSignature(signatureImage)
        ReportRepository.save(context: context, snapshot: snapshot)
        activeAlert = .saveSuccess
    }
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
}

#Preview {
    NavigationStack { ChecklistDevolucaoView() }
        .modelContainer(for: [ChecklistDevolucao.self, CheckListHistorico.self], inMemory: true)
}
