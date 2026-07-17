//
//  ChecklistView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import PencilKit
import SwiftData

struct ChecklistView: View {
    @StateObject private var viewModel = ChecklistEntregaViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
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
        let c = viewModel.checklistEntrega
        return !(c.cliente ?? "").trimmingCharacters(in: .whitespaces).isEmpty
            && !c.placa.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.funcionario.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.horaRegistro.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.modelo.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.kmAtual.trimmingCharacters(in: .whitespaces).isEmpty
            && !c.numeroReserva.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    AWScreenTitle(
                        title: "Checklist de Entrega",
                        subtitle: "Documente a saída do veículo"
                    )
                    
                    AWSectionCard(title: "Cliente e reserva") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "Nome do cliente",
                                text: Binding(
                                    get: { viewModel.checklistEntrega.cliente ?? "" },
                                    set: { viewModel.checklistEntrega.cliente = $0 }
                                )
                            )
                            AWTextField(
                                placeholder: "Nº da reserva",
                                text: $viewModel.checklistEntrega.numeroReserva,
                                keyboard: .asciiCapable,
                                autocapitalization: .characters
                            )
                            AWTextField(
                                placeholder: "CPF / Documento",
                                text: $viewModel.checklistEntrega.documentoCliente,
                                keyboard: .numbersAndPunctuation,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "Telefone (SMS / iMessage)",
                                text: $viewModel.checklistEntrega.telefoneCliente,
                                keyboard: .phonePad,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "E-mail do cliente",
                                text: $viewModel.checklistEntrega.emailCliente,
                                keyboard: .emailAddress,
                                autocapitalization: .never
                            )
                            Text("Avisos da reserva serão enviados ao telefone e e-mail.")
                                .font(AWTheme.caption(11))
                                .foregroundStyle(AWTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    AWSectionCard(title: "Veículo") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "Placa",
                                text: $viewModel.checklistEntrega.placa,
                                autocapitalization: .characters
                            )
                            AWBrandModelPicker(
                                marca: $viewModel.checklistEntrega.marca,
                                modelo: $viewModel.checklistEntrega.modelo,
                                kind: .car
                            )
                            AWTextField(placeholder: "Cor", text: $viewModel.checklistEntrega.cor)
                            AWTextField(
                                placeholder: "KM atual",
                                text: $viewModel.checklistEntrega.kmAtual,
                                keyboard: .numberPad,
                                autocapitalization: .never
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Registro") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "Funcionário responsável",
                                text: $viewModel.checklistEntrega.funcionario
                            )
                            AWDateField(title: "Data", date: $viewModel.checklistEntrega.dataRegistro)
                            AWTextField(
                                placeholder: "Hora (HH:mm)",
                                text: $viewModel.checklistEntrega.horaRegistro,
                                keyboard: .numbersAndPunctuation,
                                autocapitalization: .never
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Combustível e condição") {
                        VStack(spacing: 12) {
                            AWFuelSlider(
                                value: $viewModel.checklistEntrega.combustivel,
                                labelProvider: viewModel.sliderLabel(for:)
                            )
                            AWPickerField(
                                title: "Condição geral",
                                selection: $viewModel.condicao,
                                options: CondicaoGeral.allCases
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Itens de inspeção") {
                        AWInspectionList(items: $viewModel.checklistEntrega.itensInspecao)
                    }
                    
                    AWSectionCard(title: "Observações") {
                        AWNotesEditor(
                            text: $viewModel.checklistEntrega.observacoes,
                            placeholder: "Avarias pré-existentes, acessórios extras..."
                        )
                    }
                    
                    AWSectionCard {
                        AWPhotoGallery(
                            ownerId: viewModel.checklistEntrega.id.uuidString,
                            ownerType: .entrega,
                            title: "Fotos do veículo"
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
                    message: Text("Reserva aberta. Em seguida você pode enviar o aviso por SMS/iMessage e e-mail."),
                    dismissButton: .default(Text("OK")) {
                        let c = viewModel.checklistEntrega
                        notifyPayload = MessageNotifyService.payloadReservaAberta(
                            numero: c.numeroReserva,
                            cliente: c.cliente ?? "",
                            telefone: c.telefoneCliente,
                            email: c.emailCliente,
                            placa: c.placa,
                            marca: c.marca,
                            modelo: c.modelo
                        )
                    }
                )
            case .validationError:
                return Alert(title: Text("Atenção"), message: Text("Preencha cliente, nº da reserva, placa, modelo, KM, funcionário e hora."), dismissButton: .default(Text("OK")))
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
        viewModel.salvarChecklistEntrega(context: nil)
        
        let c = viewModel.checklistEntrega
        let signatureImage = SignatureCapture.image(from: canvasView.drawing)
        
        var snapshot = ReportSnapshot(
            id: c.id,
            tipo: "Entrega",
            titulo: "Checklist de Entrega",
            cliente: c.cliente ?? "",
            placa: c.placa,
            funcionario: c.funcionario,
            dataRegistro: c.dataRegistro,
            horaRegistro: c.horaRegistro,
            campos: [
                "Nº Reserva": c.numeroReserva,
                "Documento": c.documentoCliente,
                "Telefone": c.telefoneCliente,
                "E-mail": c.emailCliente,
                "Marca": c.marca,
                "Modelo": c.modelo,
                "Cor": c.cor,
                "KM": c.kmAtual,
                "Combustível": viewModel.sliderLabel(for: c.combustivel),
                "Condição": c.condicaoGeral
            ],
            observacoes: c.observacoes,
            ownerId: c.id.uuidString,
            itensInspecao: c.itensInspecao
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
    NavigationStack { ChecklistView() }
        .modelContainer(for: [CheckListHistorico.self], inMemory: true)
}
