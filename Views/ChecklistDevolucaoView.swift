import SwiftUI
import PencilKit

struct ChecklistDevolucaoView: View {
    @ObservedObject var viewModel = ChecklistDevolucaoViewModel()
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
        ![viewModel.checklistDevolucao.placa,
          viewModel.checklistDevolucao.funcionario,
          viewModel.checklistDevolucao.horaRegistro].contains(where: \.isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Checklist de Devolução")
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
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
            CustomTextField(placeholder: "Placa", text: $viewModel.checklistDevolucao.placa)
            CustomTextField(placeholder: "Funcionário", text: $viewModel.checklistDevolucao.funcionario)

            HStack {
                DatePicker("Data de Devolução", selection: $viewModel.checklistDevolucao.dataRegistro, displayedComponents: .date)
                    .labelsHidden()
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(colorScheme == .dark ? Color.white : Color.gray, lineWidth: 1))

                CustomTextField(placeholder: "Hora (HH:mm)", text: $viewModel.checklistDevolucao.horaRegistro)
                    .keyboardType(.numbersAndPunctuation)
            }
        }
    }

    private var fuelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Combustível na Devolução")
                .font(.headline)
            
            Slider(value: $viewModel.checklistDevolucao.combustivel, in: 0...1, step: 0.125)
                .accentColor(.blue)
            
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
            Text("Observações da Devolução")
                .font(.headline)
            
            TextEditor(text: $viewModel.checklistDevolucao.observacoes)
                .frame(height: 100)
                .padding(8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
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
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))

                Button(action: clearCanvas) {
                    Text("Limpar")
                        .font(.caption)
                        .padding(5)
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .padding(8)
            }
        }
    }

    private var actionButtons: some View {
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

    private func saveChecklist() {
        if isFormValid {
            viewModel.salvarChecklistDevolucao()
            DispatchQueue.main.async {
                activeAlert = .saveSuccess
            }
        } else {
            DispatchQueue.main.async {
                activeAlert = .validationError
            }
        }
    }

    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        canvasView.becomeFirstResponder()
    }
}

struct HomeChecklist: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
            .frame(maxWidth: .infinity)
    }
}

struct ChecklistDevolucaoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChecklistDevolucaoView()
                .preferredColorScheme(.dark)

            ChecklistDevolucaoView()
                .preferredColorScheme(.light)
        }
    }
}
