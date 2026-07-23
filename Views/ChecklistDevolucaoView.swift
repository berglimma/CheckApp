//
//  ChecklistDevolucaoView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData

struct ChecklistDevolucaoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = ChecklistDevolucaoViewModel()
    @StateObject private var signaturePad = SignaturePadController()
    @State private var activeAlert: AlertType?
    @State private var notifyPayload: MessageComposePayload?
    @State private var buscaReserva: String = ""
    @State private var reservasFiltradas: [ReservaEntrega] = []
    @State private var isApplyingReserva = false
    @State private var reservaAlertMessage: String = ""
    @State private var showReservaAlert = false
    
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
                    
                    AWSectionCard(title: "Reserva") {
                        VStack(alignment: .leading, spacing: 12) {
                            AWTextField(
                                placeholder: "Buscar por nº, cliente ou e-mail",
                                text: $buscaReserva,
                                keyboard: .asciiCapable,
                                autocapitalization: .never
                            )
                            
                            AWTextField(
                                placeholder: "Nº da reserva",
                                text: $viewModel.checklistDevolucao.numeroReserva,
                                keyboard: .asciiCapable,
                                autocapitalization: .characters
                            )
                            
                            if viewModel.checklistDevolucao.reservaAtrelada {
                                Button {
                                    limparSelecaoReserva()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AWTheme.success)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Reserva \(viewModel.checklistDevolucao.numeroReserva) selecionada")
                                                .font(AWTheme.headline(13))
                                                .foregroundStyle(AWTheme.success)
                                            Text("Toque aqui ou na lista para desmarcar")
                                                .font(AWTheme.caption(11))
                                                .foregroundStyle(AWTheme.textSecondary)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "xmark.circle")
                                            .foregroundStyle(AWTheme.textSecondary)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AWTheme.success.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if reservasFiltradas.isEmpty {
                                Text(
                                    buscaReserva.isEmpty
                                        ? "Nenhuma reserva disponível. Salve uma entrega com nº de reserva."
                                        : "Nenhuma reserva encontrada para “\(buscaReserva)”."
                                )
                                .font(AWTheme.caption(12))
                                .foregroundStyle(AWTheme.textSecondary)
                            } else {
                                Text("Toque para selecionar · toque de novo para desmarcar")
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(AWTheme.textSecondary)
                                
                                AWReservaListCard(reservas: reservasFiltradas) { reserva in
                                    Button {
                                        toggleReserva(reserva)
                                    } label: {
                                        reservaRow(reserva)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    AWSectionCard(title: "Cliente") {
                        VStack(spacing: 12) {
                            AWTextField(placeholder: "Nome do cliente", text: $viewModel.checklistDevolucao.cliente)
                            AWTextField(
                                placeholder: "CPF / Documento",
                                text: $viewModel.checklistDevolucao.documentoCliente,
                                keyboard: .numberPad,
                                autocapitalization: .never
                            )
                            .onChange(of: viewModel.checklistDevolucao.documentoCliente) { _, novoValor in
                                let formatado = DocumentFormatter.cpf(novoValor)
                                if formatado != novoValor {
                                    viewModel.checklistDevolucao.documentoCliente = formatado
                                }
                            }
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
                            AWFuncionarioPicker(
                                funcionario: $viewModel.checklistDevolucao.funcionario,
                                title: "Funcionário responsável"
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
                        AWSignaturePad(controller: signaturePad)
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
        .alert("Reserva", isPresented: $showReservaAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reservaAlertMessage)
        }
        .onAppear {
            atualizarListaReservas()
        }
        .onChange(of: buscaReserva) { _, _ in
            atualizarListaReservas()
        }
        .onChange(of: viewModel.checklistDevolucao.numeroReserva) { _, novoValor in
            guard !isApplyingReserva else { return }
            tentarPreencherPeloNumero(novoValor)
        }
    }
    
    private func reservaRow(_ reserva: ReservaEntrega) -> some View {
        let selecionada = viewModel.checklistDevolucao.reservaAtrelada
            && viewModel.checklistDevolucao.numeroReserva.caseInsensitiveCompare(reserva.numeroReserva) == .orderedSame
        
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: selecionada ? "checkmark.circle.fill" : "doc.text.fill")
                .foregroundStyle(selecionada ? AWTheme.success : AWTheme.accent)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Reserva \(reserva.numeroReserva)")
                    .font(AWTheme.headline(13))
                    .foregroundStyle(AWTheme.textPrimary)
                Text(reserva.cliente.isEmpty ? "Cliente não informado" : reserva.cliente)
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textSecondary)
                if !reserva.emailCliente.isEmpty {
                    Text(reserva.emailCliente)
                        .font(AWTheme.caption(11))
                        .foregroundStyle(AWTheme.textSecondary)
                }
                Text("\(reserva.placa) · \(reserva.marca) \(reserva.modelo)".trimmingCharacters(in: .whitespaces))
                    .font(AWTheme.caption(11))
                    .foregroundStyle(AWTheme.textSecondary)
                Text(reserva.status.titulo)
                    .font(AWTheme.caption(10))
                    .foregroundStyle(reserva.status == .emManutencao ? AWTheme.danger : AWTheme.accent)
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AWTheme.textSecondary.opacity(0.5))
        }
        .padding(10)
        .background(selecionada ? AWTheme.success.opacity(0.12) : AWTheme.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selecionada ? AWTheme.success.opacity(0.5) : AWTheme.stroke, lineWidth: 1)
        )
    }
    
    private func atualizarListaReservas() {
        reservasFiltradas = ReservaStore.search(query: buscaReserva, context: context)
    }
    
    private func tentarPreencherPeloNumero(_ numero: String) {
        let key = ReservaEntrega.normalize(numero)
        guard key.count >= 2 else {
            if key.isEmpty {
                viewModel.checklistDevolucao.reservaAtrelada = false
            }
            return
        }
        
        if let reserva = ReservaStore.find(byNumero: key, context: context) {
            aplicarReserva(reserva, silencioso: true)
        } else {
            viewModel.checklistDevolucao.reservaAtrelada = false
        }
    }
    
    private func toggleReserva(_ reserva: ReservaEntrega) {
        let jaSelecionada = viewModel.checklistDevolucao.reservaAtrelada
            && viewModel.checklistDevolucao.numeroReserva.caseInsensitiveCompare(reserva.numeroReserva) == .orderedSame
        if jaSelecionada {
            limparSelecaoReserva()
        } else {
            aplicarReserva(reserva, silencioso: true)
        }
    }
    
    private func limparSelecaoReserva() {
        isApplyingReserva = true
        defer { isApplyingReserva = false }
        
        let c = viewModel.checklistDevolucao
        c.numeroReserva = ""
        c.reservaAtrelada = false
        buscaReserva = ""
        atualizarListaReservas()
    }
    
    private func aplicarReserva(_ reserva: ReservaEntrega, silencioso: Bool = false) {
        isApplyingReserva = true
        defer { isApplyingReserva = false }
        
        let c = viewModel.checklistDevolucao
        c.numeroReserva = reserva.numeroReserva
        c.reservaAtrelada = true
        c.cliente = reserva.cliente
        c.documentoCliente = reserva.documentoCliente
        c.telefoneCliente = reserva.telefoneCliente
        c.emailCliente = reserva.emailCliente
        c.placa = reserva.placa
        c.marca = reserva.marca
        c.modelo = reserva.modelo
        c.cor = reserva.cor
        c.kmSaida = reserva.kmAtual
        if c.funcionario.trimmingCharacters(in: .whitespaces).isEmpty {
            c.funcionario = reserva.funcionario
        }
        
        buscaReserva = reserva.numeroReserva
        atualizarListaReservas()
        
        if !silencioso {
            reservaAlertMessage = "Reserva \(reserva.numeroReserva) selecionada. Toque de novo para desmarcar."
            showReservaAlert = true
        }
    }
    
    private func saveChecklist() {
        guard isFormValid else {
            activeAlert = .validationError
            return
        }
        
        let c = viewModel.checklistDevolucao
        c.numeroReserva = ReservaEntrega.normalize(c.numeroReserva)
        if !c.reservaAtrelada, ReservaStore.find(byNumero: c.numeroReserva, context: context) != nil {
            c.reservaAtrelada = true
        }
        
        c.assinaturaData = signaturePad.pngData()
        viewModel.salvarChecklistDevolucao(context: context)
        
        if !c.numeroReserva.isEmpty {
            ReservaStore.closeOnDevolucao(
                numero: c.numeroReserva,
                kmRetorno: c.kmRetorno,
                context: context
            )
        }
        
        let signatureImage = SignatureCapture.image(from: signaturePad)
        
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
                "Nº Reserva": c.numeroReserva,
                "Reserva atrelada": c.reservaAtrelada ? "Sim" : "Não",
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
}

#Preview {
    NavigationStack { ChecklistDevolucaoView() }
        .modelContainer(for: [ChecklistDevolucao.self, CheckListHistorico.self], inMemory: true)
}
