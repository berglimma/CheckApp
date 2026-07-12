import SwiftUI
import PencilKit
import SwiftData

struct TrocaProvisoriaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var form = TrocaProvisoria()
    @State private var canvasView = PKCanvasView()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var saved = false
    
    private var isFormValid: Bool {
        !form.cliente.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.funcionario.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.placaOriginal.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.placaProvisorio.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.motivoCategoria.trimmingCharacters(in: .whitespaces).isEmpty
            && !form.horaRegistro.trimmingCharacters(in: .whitespaces).isEmpty
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
                                placeholder: "Telefone",
                                text: $form.telefoneCliente,
                                keyboard: .phonePad,
                                autocapitalization: .never
                            )
                            AWTextField(placeholder: "Funcionário", text: $form.funcionario)
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
                            AWTextField(
                                placeholder: "Placa original",
                                text: $form.placaOriginal,
                                autocapitalization: .characters
                            )
                            AWTextField(placeholder: "Modelo original", text: $form.modeloOriginal)
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
                            AWTextField(placeholder: "Modelo provisório", text: $form.modeloProvisorio)
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
                        AWSignaturePad(canvasView: $canvasView) {
                            canvasView.drawing = PKDrawing()
                        }
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
                if saved { dismiss() }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func fuelLabel(_ value: Double) -> String {
        "\(Int(round(value * 8)))/8"
    }
    
    private func save() {
        guard isFormValid else {
            alertMessage = "Preencha cliente, motivo da troca, placas, funcionário e hora."
            showAlert = true
            saved = false
            return
        }
        
        if let data = try? JSONEncoder().encode(form) {
            UserDefaults.standard.set(data, forKey: "trocaProvisoria_\(form.id.uuidString)")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let signatureImage = SignatureCapture.image(from: canvasView.drawing)
        
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
                "Documento": form.documentoCliente,
                "Telefone": form.telefoneCliente,
                "Motivo": form.motivoCompleto,
                "Categoria do motivo": form.motivoCategoria,
                "Placa original": form.placaOriginal,
                "Modelo original": form.modeloOriginal,
                "KM original": form.kmOriginal,
                "Combustível original": fuelLabel(form.combustivelOriginal),
                "Placa provisória": form.placaProvisorio,
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
        
        alertMessage = "Troca provisória salva. Você pode exportar o PDF em Histórico ou Relatórios."
        saved = true
        showAlert = true
    }
}

#Preview {
    NavigationStack { TrocaProvisoriaView() }
        .modelContainer(for: [CheckListHistorico.self], inMemory: true)
}
