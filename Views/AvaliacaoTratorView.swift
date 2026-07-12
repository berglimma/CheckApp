import SwiftUI
import PencilKit
import SwiftData

struct AvaliacaoTratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var form = AvaliacaoTrator()
    @State private var condicao: CondicaoGeral = .boa
    @State private var canvasView = PKCanvasView()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var saved = false
    
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
                                keyboard: .numbersAndPunctuation,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "Telefone",
                                text: $form.telefoneCliente,
                                keyboard: .phonePad,
                                autocapitalization: .never
                            )
                            AWTextField(placeholder: "Avaliador / funcionário", text: $form.funcionario)
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
                            AWTextField(placeholder: "Marca", text: $form.marca)
                            AWTextField(placeholder: "Modelo", text: $form.modelo)
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
                        AWSignaturePad(canvasView: $canvasView) {
                            canvasView.drawing = PKDrawing()
                        }
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
                if saved { dismiss() }
            }
        } message: {
            Text(alertMessage)
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
        
        let signatureImage = SignatureCapture.image(from: canvasView.drawing)
        
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
            ? "Avaliação salva. Equipamento aprovado para uso."
            : "Avaliação salva. Equipamento NÃO aprovado para uso."
        saved = true
        showAlert = true
    }
}

#Preview {
    NavigationStack { AvaliacaoTratorView() }
        .modelContainer(for: [CheckListHistorico.self], inMemory: true)
}
