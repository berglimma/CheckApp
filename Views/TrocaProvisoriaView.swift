//
//  TrocaProvisoriaView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData

struct TrocaProvisoriaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var form = TrocaProvisoria()
    @StateObject private var signaturePad = SignaturePadController()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var saved = false
    @State private var buscaReserva = ""
    @State private var reservasFiltradas: [ReservaEntrega] = []
    @State private var isApplyingReserva = false
    @State private var notifyPayload: MessageComposePayload?
    
    private var isFormValid: Bool {
        !form.cliente.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.funcionario.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.placaOriginal.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.placaProvisorio.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.motivoCategoria.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.horaRegistro.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.numeroReserva.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.nomeQuemRetornou.trimmingCharacters(in: .whitespaces).isEmpty
            && (form.motivoSelecionado != .outro || !form.motivo.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    AWScreenTitle(
                        title: "Troca Provisória",
                        subtitle: "Substitua o veículo temporariamente"
                    )
                    
                    AWSectionCard(title: "Buscar reserva") {
                        VStack(alignment: .leading, spacing: 12) {
                            AWTextField(
                                placeholder: "Buscar por nº, cliente, e-mail, placa ou modelo",
                                text: $buscaReserva,
                                keyboard: .asciiCapable,
                                autocapitalization: .never
                            )
                            
                            AWTextField(
                                placeholder: "Nº da reserva",
                                text: $form.numeroReserva,
                                keyboard: .asciiCapable,
                                autocapitalization: .characters
                            )
                            
                            if form.reservaAtrelada {
                                Button {
                                    limparSelecaoReserva()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AWTheme.success)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Reserva \(form.numeroReserva) selecionada")
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
                            
                            AWTextField(
                                placeholder: "Nome de quem retornou o carro",
                                text: $form.nomeQuemRetornou
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Cliente e registro") {
                        VStack(spacing: 12) {
                            AWTextField(placeholder: "Cliente", text: $form.cliente)
                            AWTextField(
                                placeholder: "CPF / Documento",
                                text: $form.documentoCliente,
                                keyboard: .numbersAndPunctuation,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "Telefone (SMS / iMessage)",
                                text: $form.telefoneCliente,
                                keyboard: .phonePad,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "E-mail do cliente",
                                text: $form.emailCliente,
                                keyboard: .emailAddress,
                                autocapitalization: .never
                            )
                            Text("Alterações na reserva serão notificadas ao cliente.")
                                .font(AWTheme.caption(11))
                                .foregroundStyle(AWTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            AWFuncionarioPicker(
                                funcionario: $form.funcionario,
                                title: "Funcionário responsável"
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
                    
                    AWSectionCard(title: "Motivo da troca") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Qual o motivo da troca?")
                                .font(AWTheme.headline(15))
                                .foregroundStyle(AWTheme.textPrimary)
                            
                            Text("Selecione a opção que melhor descreve a troca.")
                                .font(AWTheme.caption(12))
                                .foregroundStyle(AWTheme.textSecondary)
                            
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8)
                                ],
                                spacing: 8
                            ) {
                                ForEach(MotivoTroca.allCases) { opcao in
                                    Button {
                                        form.motivoCategoria = opcao.rawValue
                                    } label: {
                                        Text(opcao.rawValue)
                                            .font(AWTheme.caption(12))
                                            .foregroundStyle(
                                                form.motivoCategoria == opcao.rawValue
                                                    ? .white
                                                    : AWTheme.textPrimary
                                            )
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .padding(.horizontal, 8)
                                            .background(
                                                form.motivoCategoria == opcao.rawValue
                                                    ? AWTheme.moduleTroca
                                                    : AWTheme.fieldFill
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(
                                                        form.motivoCategoria == opcao.rawValue
                                                            ? AWTheme.moduleTroca
                                                            : AWTheme.stroke,
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            AWNotesEditor(
                                text: $form.motivo,
                                placeholder: form.motivoSelecionado == .outro
                                    ? "Descreva o motivo da troca"
                                    : "Detalhes do motivo (opcional)",
                                minHeight: 80
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Veículo original") {
                        VStack(spacing: 12) {
                            if form.reservaAtrelada {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(AWTheme.success)
                                    Text("Preenchido pela reserva \(form.numeroReserva)")
                                        .font(AWTheme.caption(12))
                                        .foregroundStyle(AWTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            AWTextField(
                                placeholder: "Placa original",
                                text: $form.placaOriginal,
                                autocapitalization: .characters
                            )
                            AWBrandModelPicker(
                                marca: $form.marcaOriginal,
                                modelo: $form.modeloOriginal,
                                kind: .car,
                                title: "Marca e modelo (original)"
                            )
                            AWTextField(
                                placeholder: "KM atual",
                                text: $form.kmOriginal,
                                keyboard: .numberPad,
                                autocapitalization: .never
                            )
                            AWFuelSlider(value: $form.combustivelOriginal, labelProvider: fuelLabel)
                        }
                    }
                    
                    AWSectionCard(title: "Veículo provisório") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "Placa provisória",
                                text: $form.placaProvisorio,
                                autocapitalization: .characters
                            )
                            AWBrandModelPicker(
                                marca: $form.marcaProvisorio,
                                modelo: $form.modeloProvisorio,
                                kind: .car,
                                title: "Marca e modelo (provisório)"
                            )
                            AWTextField(
                                placeholder: "KM atual",
                                text: $form.kmProvisorio,
                                keyboard: .numberPad,
                                autocapitalization: .never
                            )
                            AWFuelSlider(value: $form.combustivelProvisorio, labelProvider: fuelLabel)
                            AWDateField(title: "Previsão de devolução", date: $form.previsaoDevolucao)
                        }
                    }
                    
                    AWSectionCard(title: "Inspeção do provisório") {
                        AWInspectionList(items: $form.itensInspecao)
                    }
                    
                    AWSectionCard(title: "Observações") {
                        AWNotesEditor(text: $form.observacoes)
                    }
                    
                    AWSectionCard {
                        AWPhotoGallery(
                            ownerId: form.id.uuidString,
                            ownerType: .troca,
                            title: "Fotos da troca"
                        )
                    }
                    
                    AWSectionCard {
                        AWSignaturePad(controller: signaturePad)
                    }
                    
                    VStack(spacing: 10) {
                        AWPrimaryButton(title: "Salvar troca") { save() }
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
                    abrirAvisoAposTroca()
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
        .onAppear {
            atualizarListaReservas()
        }
        .onChange(of: buscaReserva) { _, _ in
            atualizarListaReservas()
        }
        .onChange(of: form.numeroReserva) { _, novoValor in
            guard !isApplyingReserva else { return }
            tentarPreencherPeloNumero(novoValor)
        }
    }
    
    private func reservaRow(_ reserva: ReservaEntrega) -> some View {
        let selecionada = form.reservaAtrelada
            && form.numeroReserva.caseInsensitiveCompare(reserva.numeroReserva) == .orderedSame
        
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: selecionada ? "checkmark.circle.fill" : "doc.text.fill")
                .foregroundStyle(selecionada ? AWTheme.success : AWTheme.moduleTroca)
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
                    .foregroundStyle(reserva.status == .emManutencao ? AWTheme.danger : AWTheme.moduleTroca)
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
    
    private func fuelLabel(_ value: Double) -> String {
        "\(Int(round(value * 8)))/8"
    }
    
    private func atualizarListaReservas() {
        reservasFiltradas = ReservaStore.search(query: buscaReserva, context: context)
    }
    
    private func tentarPreencherPeloNumero(_ numero: String) {
        let key = ReservaEntrega.normalize(numero)
        guard key.count >= 2 else {
            if key.isEmpty {
                form.reservaAtrelada = false
            }
            return
        }
        
        if let reserva = ReservaStore.find(byNumero: key, context: context) {
            aplicarReserva(reserva, silencioso: true)
        } else {
            form.reservaAtrelada = false
        }
    }
    
    private func toggleReserva(_ reserva: ReservaEntrega) {
        let jaSelecionada = form.reservaAtrelada
            && form.numeroReserva.caseInsensitiveCompare(reserva.numeroReserva) == .orderedSame
        if jaSelecionada {
            limparSelecaoReserva()
        } else {
            aplicarReserva(reserva, silencioso: true)
        }
    }
    
    private func limparSelecaoReserva() {
        isApplyingReserva = true
        defer { isApplyingReserva = false }
        
        form.numeroReserva = ""
        form.reservaAtrelada = false
        buscaReserva = ""
        atualizarListaReservas()
    }
    
    private func aplicarReserva(_ reserva: ReservaEntrega, silencioso: Bool = false) {
        isApplyingReserva = true
        defer { isApplyingReserva = false }
        
        form.numeroReserva = reserva.numeroReserva
        form.reservaAtrelada = true
        form.cliente = reserva.cliente
        form.documentoCliente = reserva.documentoCliente
        form.telefoneCliente = reserva.telefoneCliente
        form.emailCliente = reserva.emailCliente
        form.placaOriginal = reserva.placa
        form.marcaOriginal = reserva.marca
        form.modeloOriginal = reserva.modelo
        form.kmOriginal = reserva.kmAtual
        buscaReserva = reserva.numeroReserva
        
        if form.nomeQuemRetornou.trimmingCharacters(in: .whitespaces).isEmpty {
            form.nomeQuemRetornou = reserva.cliente
        }
        
        atualizarListaReservas()
        
        if !silencioso {
            alertMessage = "Reserva \(reserva.numeroReserva) selecionada. Toque de novo para desmarcar."
            saved = false
            showAlert = true
        }
    }
    
    private func abrirAvisoAposTroca() {
        let isManutencao = form.motivoSelecionado == .manutencao
        if isManutencao {
            notifyPayload = MessageNotifyService.payloadManutencao(
                numero: form.numeroReserva,
                cliente: form.cliente,
                telefone: form.telefoneCliente,
                email: form.emailCliente,
                placa: form.placaOriginal,
                motivo: form.motivoCompleto
            )
        } else {
            notifyPayload = MessageNotifyService.payloadReservaAlterada(
                numero: form.numeroReserva,
                cliente: form.cliente,
                telefone: form.telefoneCliente,
                email: form.emailCliente,
                detalhe: """
                Troca provisória registrada.
                Original: \(form.placaOriginal) (\(form.marcaOriginal) \(form.modeloOriginal))
                Provisório: \(form.placaProvisorio) (\(form.marcaProvisorio) \(form.modeloProvisorio))
                Motivo: \(form.motivoCompleto)
                Quem retornou: \(form.nomeQuemRetornou)
                """
            )
        }
    }
    
    private func save() {
        guard isFormValid else {
            alertMessage = "Preencha reserva, quem retornou, cliente, motivo, placas, funcionário e hora."
            showAlert = true
            saved = false
            return
        }
        
        form.numeroReserva = ReservaEntrega.normalize(form.numeroReserva)
        
        if !form.reservaAtrelada, ReservaStore.find(byNumero: form.numeroReserva, context: context) != nil {
            form.reservaAtrelada = true
        }
        
        if let data = try? JSONEncoder().encode(form) {
            UserDefaults.standard.set(data, forKey: "trocaProvisoria_\(form.id.uuidString)")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let signatureImage = SignatureCapture.image(from: signaturePad)
        
        var snapshot = ReportSnapshot(
            id: form.id,
            tipo: "Troca",
            titulo: "Troca Provisória",
            cliente: form.cliente,
            placa: "\(form.placaOriginal) → \(form.placaProvisorio)",
            funcionario: form.funcionario,
            dataRegistro: form.dataRegistro,
            horaRegistro: form.horaRegistro,
            campos: [
                "Nº Reserva": form.numeroReserva,
                "Reserva atrelada": form.reservaAtrelada ? "Sim" : "Não",
                "Quem retornou": form.nomeQuemRetornou,
                "Documento": form.documentoCliente,
                "Telefone": form.telefoneCliente,
                "E-mail": form.emailCliente,
                "Motivo": form.motivoCompleto,
                "Categoria do motivo": form.motivoCategoria,
                "Placa original": form.placaOriginal,
                "Marca original": form.marcaOriginal,
                "Modelo original": form.modeloOriginal,
                "KM original": form.kmOriginal,
                "Combustível original": fuelLabel(form.combustivelOriginal),
                "Placa provisória": form.placaProvisorio,
                "Marca provisória": form.marcaProvisorio,
                "Modelo provisório": form.modeloProvisorio,
                "KM provisório": form.kmProvisorio,
                "Combustível provisório": fuelLabel(form.combustivelProvisorio),
                "Previsão devolução": dateFormatter.string(from: form.previsaoDevolucao)
            ],
            observacoes: form.observacoes,
            ownerId: form.id.uuidString,
            itensInspecao: form.itensInspecao
        )
        snapshot.attachSignature(signatureImage)
        ReportRepository.save(context: context, snapshot: snapshot)
        
        ReservaStore.applyTroca(
            numero: form.numeroReserva,
            placaProvisorio: form.placaProvisorio,
            marcaProvisorio: form.marcaProvisorio,
            modeloProvisorio: form.modeloProvisorio,
            kmProvisorio: form.kmProvisorio,
            nomeQuemRetornou: form.nomeQuemRetornou,
            motivo: form.motivoCompleto,
            isManutencao: form.motivoSelecionado == .manutencao,
            context: context
        )
        
        alertMessage = "Troca salva. Em seguida envie o aviso por SMS/iMessage e e-mail."
        saved = true
        showAlert = true
    }
}

#Preview {
    NavigationStack { TrocaProvisoriaView() }
        .modelContainer(for: [CheckListHistorico.self], inMemory: true)
}
