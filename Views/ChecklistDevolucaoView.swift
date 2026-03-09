import SwiftUI
import PencilKit
import SwiftData

struct ChecklistDevolucaoView: View {

    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var context
    
    @StateObject private var viewModel: ChecklistDevolucaoViewModel
    
    init() {
        // The modelContext will be injected in the body
        _viewModel = StateObject(wrappedValue: ChecklistDevolucaoViewModel())
    }
    
    private func injectContextIfNeeded() {
        if viewModel.context == nil {
            viewModel.context = context
        }
    }

    @State private var canvasView = PKCanvasView()
    @State private var activeAlert: AlertType?
    @State private var navigateToHome = false

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
        !viewModel.checklistDevolucao.placa.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty &&
        !viewModel.checklistDevolucao.funcionario.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty &&
        !viewModel.checklistDevolucao.horaRegistro.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Checklist de Devolução")
                        .foregroundColor(colorScheme == .light ? .black : .white)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .center)

                   // formFields
                  //  fuelSection
                   // observationsSection
                  //  signatureSection
                   // actionButtons
                }
                .padding()
                .background(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .saveSuccess:
                    return Alert(
                        title: Text("Sucesso"),
                        message: Text("Checklist salvo com sucesso!"),
                        dismissButton: .default(Text("OK"))
                    )
                case .validationError:
                    return Alert(
                        title: Text("Erro"),
                        message: Text("Preencha todos os campos antes de salvar."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeCheckListView()
            }
            .navigationBarBackButtonHidden(true)
            .onAppear(perform: injectContextIfNeeded)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: saveChecklist) {
                Text("Salvar")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }

            Button(action: { navigateToHome = true }) {
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
    }

    private func saveChecklist() {
        if isFormValid {

            // Salva assinatura como Data
            viewModel.checklistDevolucao.assinaturaData =
                canvasView.drawing.dataRepresentation()

            viewModel.salvarChecklistDevolucao(context: context)

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

struct HomeCheck: View {
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
