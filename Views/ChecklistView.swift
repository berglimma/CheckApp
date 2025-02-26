import PDFKit
import SwiftUI
import PencilKit

struct ChecklistView: View {
    @ObservedObject var viewModel = ChecklistEntregaViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var canvasView = PKCanvasView()
    @State private var activeAlert: AlertType?

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
        ![(viewModel.checklistEntrega.cliente ?? ""),
          viewModel.checklistEntrega.placa,
          viewModel.checklistEntrega.funcionario,
          viewModel.checklistEntrega.horaRegistro].contains(where: \.isEmpty)
    }

    var body: some View {
        HStack(spacing: 50) {
            ScrollView {
                NavigationLink(destination: HomeCheckListView()) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Checklist de Entrega")
                            .foregroundColor(colorScheme == .light ? .black : .white)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }

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

    private var formFields: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CustomTextField(placeholder: "Cliente", text: Binding(get: { viewModel.checklistEntrega.cliente ?? "" }, set: { viewModel.checklistEntrega.cliente = $0 }))
                CustomTextField(placeholder: "Placa", text: $viewModel.checklistEntrega.placa)
                CustomTextField(placeholder: "Funcionário", text: $viewModel.checklistEntrega.funcionario)
            }
            
            HStack(spacing: 16) {
                DatePicker("Data", selection: $viewModel.checklistEntrega.dataRegistro, displayedComponents: .date)
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

    private var fuelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Combustível na Entrega")
                .font(.headline)
            
            Slider(value: $viewModel.checklistEntrega.combustivel, in: 0...1, step: 0.125)
                .accentColor(.green)
            
            fuelLabels
        }
    }

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
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(colorScheme == .dark ? Color.white : Color.gray, lineWidth: 1))
            }
        }
    }

    private var signatureSection: some View {
        VStack(alignment: .leading) {
            Text("Assinatura Digital")
                .font(.headline)
            
            ZStack(alignment: .topTrailing) {
                CanvasView(canvasView: $canvasView)
                    .frame(height: 120)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(colorScheme == .dark ? Color.white : Color.gray, lineWidth: 1))
                
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

    private var actionButtons: some View {
        HStack {
            Spacer()
            HStack(spacing: 25) {
                Button(action: saveChecklist) {
                    Text("Salvar")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: 120)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }
            Spacer()
        }
        .padding()
    }

    private func saveChecklist() {
        if isFormValid {
            viewModel.salvarChecklistEntrega()
            activeAlert = .saveSuccess
        } else {
            activeAlert = .validationError
        }
    }

    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        canvasView.becomeFirstResponder()
    }
}

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

struct ChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChecklistView().preferredColorScheme(.dark)
            ChecklistView().preferredColorScheme(.light)
        }
    }
}
