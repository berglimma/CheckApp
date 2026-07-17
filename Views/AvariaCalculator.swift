//
//  AvariaCalculator.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import PDFKit

struct AvariaCalculator: View {
    @StateObject private var viewModel = AvariaCalculatorViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var reportId = UUID()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var saved = false
    @State private var notifyPayload: MessageComposePayload?
    
    private var totalAvarias: Double {
        viewModel.avarias.reduce(0) { $0 + $1.value }
    }
    
    private var canGenerate: Bool {
        !viewModel.avarias.isEmpty
            && !viewModel.placaCarro.trimmingCharacters(in: .whitespaces).isEmpty
            && !viewModel.cliente.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    AWScreenTitle(
                        title: "Cálculo de Avarias",
                        subtitle: "Registre danos e gere o relatório"
                    )
                    
                    AWSectionCard(title: "Identificação") {
                        VStack(spacing: 12) {
                            AWTextField(placeholder: "Cliente", text: $viewModel.cliente)
                            AWTextField(
                                placeholder: "Telefone (SMS / iMessage)",
                                text: $viewModel.telefoneCliente,
                                keyboard: .phonePad,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "E-mail do cliente",
                                text: $viewModel.emailCliente,
                                keyboard: .emailAddress,
                                autocapitalization: .never
                            )
                            Text("Avisos de avarias serão enviados ao telefone e e-mail.")
                                .font(AWTheme.caption(11))
                                .foregroundStyle(AWTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            AWTextField(placeholder: "Funcionário", text: $viewModel.funcionario)
                            AWTextField(placeholder: "Modelo / veículo", text: $viewModel.nomeCarro)
                            AWTextField(
                                placeholder: "Placa",
                                text: $viewModel.placaCarro,
                                autocapitalization: .characters
                            )
                            AWTextField(
                                placeholder: "KM atual",
                                text: $viewModel.kmAtual,
                                keyboard: .numberPad,
                                autocapitalization: .never
                            )
                            Text("Data: \(AvariaCalculatorViewModel.formatarData(Date()))")
                                .font(AWTheme.caption(13))
                                .foregroundStyle(AWTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    AWSectionCard(title: "Nova avaria") {
                        VStack(spacing: 12) {
                            AWPickerField(
                                title: "Categoria",
                                selection: $viewModel.categoria,
                                options: AvariaCategoria.allCases
                            )
                            AWTextField(placeholder: "Descrição do dano", text: $viewModel.avariaName)
                            AWTextField(
                                placeholder: "Local do dano (ex.: porta D.E.)",
                                text: $viewModel.localDano
                            )
                            AWTextField(
                                placeholder: "Valor (R$)",
                                text: $viewModel.avariaValue,
                                keyboard: .decimalPad,
                                autocapitalization: .never
                            )
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(AWTheme.danger)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            AWPrimaryButton(
                                title: "Adicionar avaria",
                                isDisabled: viewModel.avariaName.isEmpty || viewModel.avariaValue.isEmpty
                            ) {
                                viewModel.addAvaria()
                            }
                        }
                    }
                    
                    AWSectionCard(title: "Avarias adicionadas") {
                        if viewModel.avarias.isEmpty {
                            Text("Nenhuma avaria adicionada ainda.")
                                .font(AWTheme.body(14))
                                .foregroundStyle(AWTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(viewModel.avarias.enumerated()), id: \.element.id) { index, avaria in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .top, spacing: 10) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(avaria.name)
                                                    .font(AWTheme.headline(14))
                                                    .foregroundStyle(AWTheme.textPrimary)
                                                Text("\(avaria.categoria) · \(avaria.localDano.isEmpty ? "Local não informado" : avaria.localDano)")
                                                    .font(AWTheme.caption(12))
                                                    .foregroundStyle(AWTheme.textSecondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text("R$ \(String(format: "%.2f", avaria.value))")
                                                .font(AWTheme.headline(14))
                                                .foregroundStyle(AWTheme.moduleAvarias)
                                                .fixedSize()
                                            
                                            Button {
                                                viewModel.deleteAvaria(at: IndexSet(integer: index))
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(AWTheme.danger)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    
                                    if index < viewModel.avarias.count - 1 {
                                        Divider().opacity(0.35)
                                    }
                                }
                                
                                Divider().padding(.vertical, 6)
                                
                                HStack {
                                    Text("Total")
                                        .font(AWTheme.headline(15))
                                    Spacer()
                                    Text("R$ \(String(format: "%.2f", totalAvarias))")
                                        .font(AWTheme.headline(16))
                                        .foregroundStyle(AWTheme.accent)
                                }
                            }
                        }
                    }
                    
                    AWSectionCard(title: "Observações") {
                        AWNotesEditor(text: $viewModel.observacoes)
                    }
                    
                    AWSectionCard {
                        AWPhotoGallery(
                            ownerId: reportId.uuidString,
                            ownerType: .avaria,
                            title: "Fotos das avarias"
                        )
                    }
                    
                    VStack(spacing: 10) {
                        AWPrimaryButton(
                            title: "Salvar avarias",
                            isDisabled: !canGenerate
                        ) {
                            save()
                        }
                        
                        AWSecondaryButton(title: "Voltar") {
                            dismiss()
                        }
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
                    let detalhe = viewModel.avarias
                        .map { "• \($0.name) — R$ \(String(format: "%.2f", $0.value))" }
                        .joined(separator: "\n")
                    notifyPayload = MessageNotifyService.payloadAvarias(
                        cliente: viewModel.cliente,
                        telefone: viewModel.telefoneCliente,
                        email: viewModel.emailCliente,
                        placa: viewModel.placaCarro,
                        veiculo: viewModel.nomeCarro,
                        total: String(format: "R$ %.2f", totalAvarias),
                        detalhe: detalhe
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
        var campos: [String: String] = [
            "Veículo": viewModel.nomeCarro,
            "KM": viewModel.kmAtual,
            "Telefone": viewModel.telefoneCliente,
            "E-mail": viewModel.emailCliente,
            "Total": String(format: "R$ %.2f", totalAvarias)
        ]
        for (index, avaria) in viewModel.avarias.enumerated() {
            campos["Avaria \(index + 1)"] = "[\(avaria.categoria)] \(avaria.name) (\(avaria.localDano)) = R$ \(String(format: "%.2f", avaria.value))"
        }
        
        let snapshot = ReportSnapshot(
            id: reportId,
            tipo: "Avarias",
            titulo: "Relatório de Avarias",
            cliente: viewModel.cliente,
            placa: viewModel.placaCarro,
            funcionario: viewModel.funcionario,
            dataRegistro: Date(),
            horaRegistro: {
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                return f.string(from: Date())
            }(),
            campos: campos,
            observacoes: viewModel.observacoes,
            ownerId: reportId.uuidString
        )
        ReportRepository.save(context: context, snapshot: snapshot)
        
        alertMessage = "Avarias salvas. Em seguida envie o aviso por SMS/iMessage e e-mail ao cliente."
        saved = true
        showAlert = true
    }
}

#Preview {
    NavigationStack { AvariaCalculator() }
}
