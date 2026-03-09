import SwiftUI
import PencilKit

struct ChecklistView: View {
    @ObservedObject var viewModel = ChecklistEntregaViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var canvasView = PKCanvasView()
    @State private var  voltaHome = false
    @State private var activeAlert: AlertType?

    // 🔹 Enum para alertas
    enum AlertType: Identifiable {
        case saveSuccess, validationError
        
        var id: Int {
            switch self {
            case .saveSuccess: return 0
            case .validationError: return 1
            }
        }
    }

    // 🔹 Verifica se o formulário está preenchido corretamente
    private var isFormValid: Bool {
        ![(viewModel.checklistEntrega.cliente ?? ""),
          viewModel.checklistEntrega.placa,
          viewModel.checklistEntrega.funcionario,
          viewModel.checklistEntrega.horaRegistro].contains(where: \.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Checklist de Entrega")
                        .foregroundColor(colorScheme == .light ? .black : .white)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .center)

                    formFields
                    fuelSection
                    observationsSection
                    signatureSection
                    actionButtons
                }
                .padding()
                .background(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(35)
                .shadow(radius: 15)
                .padding(.horizontal)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .saveSuccess:
                return Alert(title: Text("Sucesso"), message: Text("Checklist salvo com sucesso!"), dismissButton: .default(Text("OK")))
            case .validationError:
                return Alert(title: Text("Erro"), message: Text("Preencha todos os campos antes de salvar."), dismissButton: .default(Text("OK")))
            }
        }
    }

    // 🔹 Campos do formulário
    private var formFields: some View {
            VStack(spacing: 16) {
                CustomTextField(placeholder: "Placa", text: $viewModel.checklistEntrega.placa)
                CustomTextField(placeholder: "Funcionário", text: $viewModel.checklistEntrega.funcionario)
                
                HStack {
                    DatePicker("Data de Entrega", selection: $viewModel.checklistEntrega.dataRegistro, displayedComponents: .date)
                        .labelsHidden()
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(colorScheme == .dark ? Color.white : Color.gray, lineWidth: 1))
                    
                    CustomTextField(placeholder: "Hora (HH:mm)", text: $viewModel.checklistEntrega.horaRegistro)
                        .keyboardType(.numbersAndPunctuation)
            }
        }
    }

    // 🔹 Seção do combustível
    private var fuelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Combustível na Entrega")
                .font(.headline)
            
            Slider(value: $viewModel.checklistEntrega.combustivel, in: 0...1, step: 0.125)
                .accentColor(.green)
            
            fuelLabels
        }
    }

    // 🔹 Rótulos do slider de combustível
    private var fuelLabels: some View {
        HStack {
            ForEach(0..<9) { index in
                let fraction = Double(index) / 8.0
                Text(viewModel.sliderLabel(for: fraction))
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // 🔹 Seção de observações
    private var observationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Observações de Entrega")
                .font(.headline)
            
            ZStack(alignment: .topLeading) {
                if viewModel.checklistEntrega.observacoes.isEmpty {
                    Text("Digite suas observações aqui...")
                        .foregroundColor(.gray)
                        .padding(8)
                }
                TextEditor(text: $viewModel.checklistEntrega.observacoes)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
            }
        }
    }

    // 🔹 Seção de assinatura
    private var signatureSection: some View {
        VStack(alignment: .leading) {
            Text("Assinatura Digital")
                .font(.headline)
            
            ZStack(alignment: .topTrailing) {
                CanvasView(canvasView: $canvasView)
                    .frame(height: 120)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                
                Button(action: clearCanvas) {
                    Text("Limpar")
                        .font(.caption)
                        .padding(5)
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .padding(2)
            }
        }
    }

    // 🔹 Botões de ação
    private var actionButtons: some View {
        NavigationStack {
            HStack(spacing: 20) {
                Button(action: {
                    if isFormValid {
                        viewModel.salvarChecklistEntrega()
                        activeAlert = .saveSuccess

                        if let pdfURL = ChecklistPDFGenerator.gerarPDF(checklist: viewModel, assinatura: canvasView) {
                            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)

                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.windows.first?.rootViewController {
                                rootVC.present(activityVC, animated: true, completion: nil)
                            }
                        } else {
                            print("❌ Falha ao gerar o PDF.")
                        }
                    } else {
                        activeAlert = .validationError
                    }
                }) {
                    Text("Salvar")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }

                Button(action: {
                    voltaHome = true
                }) {
                    Text("Voltar")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }
            .padding(.top, 10)
            .navigationDestination(isPresented: $voltaHome) {
                HomeCheckListView()
                
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    // 🔹 Função para salvar checklist
    private func saveChecklist() {
        if isFormValid {
            viewModel.salvarChecklistEntrega()
            activeAlert = .saveSuccess
        } else {
            activeAlert = .validationError
        }
    }

    // 🔹 Função para limpar assinatura
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        canvasView.becomeFirstResponder()
    }
}

// 🔹 CustomTextField Component
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
    }
}

// 🔹 Preview
struct ChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChecklistView().preferredColorScheme(.dark)
            ChecklistView().preferredColorScheme(.light)
        }
    }
}
