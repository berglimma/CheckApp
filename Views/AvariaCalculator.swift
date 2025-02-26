import SwiftUI
import PDFKit

struct AvariaCalculator: View {
    @StateObject private var viewModel = AvariaCalculatorViewModel()
    @State private var showPDFShareSheet = false
    @Environment(\.dismiss) var dismiss
    
    @State private var nomeCarro: String = ""
    @State private var placaCarro: String = ""
    
    var body: some View {
        Form {
            // 🔹 Seção de Informações do Carro
            Section(header: Text("INFORMAÇÕES DO CARRO")) {
                VStack(spacing: 8) {
                    TextField("Nome do Carro", text: $nomeCarro)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Placa do Carro", text: $placaCarro)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Data: \(Self.formatarData(Date()))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            // 🔹 Seção de Adicionar Avarias
            Section(header: Text("ADICIONAR AVARIA")) {
                VStack(spacing: 8) {
                    TextField("Descrição da Avaria", text: $viewModel.avariaName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Valor (R$)", text: $viewModel.avariaValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: viewModel.addAvaria) {
                        Text("Adicionar Avaria")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.avariaName.isEmpty || viewModel.avariaValue.isEmpty)
                }
            }
            
            // 🔹 Seção de Lista de Avarias
            Section(header: Text("AVARIAS ADICIONADAS")) {
                if viewModel.avarias.isEmpty {
                    Text("Nenhuma avaria adicionada ainda.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                } else {
                    List {
                        ForEach(viewModel.avarias) { avaria in
                            HStack {
                                Text(avaria.name)
                                Spacer()
                                Text("R$ \(String(format: "%.2f", avaria.value))")
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: viewModel.deleteAvaria)
                    }
                    .frame(height: 120)
                }
            }
            
            // 🔹 Botões de Ação
            Section {
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.generatePDF()
                        showPDFShareSheet = true
                    }) {
                        Text("Gerar PDF")
                            .frame(maxWidth: 200)
                            .frame(height: 45)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        dismiss() // 🔹 Fecha a tela corretamente
                    }) {
                        Text("Voltar")
                            .frame(maxWidth: 200)
                            .frame(height: 45)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
    
        .navigationTitle("Cálculo de Avarias")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showPDFShareSheet) {
            if let pdfData = viewModel.generatedPDF {
                ShareSheet(activityItems: [pdfData])
            }
        }
    }
    
    // 🔹 Formata a data no estilo desejado
    static func formatarData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// 🔹 Extensão para compartilhamento de arquivos
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// 🔹 Preview no SwiftUI
struct AvariaCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AvariaCalculator()
                .preferredColorScheme(.dark)
            AvariaCalculator()
                .preferredColorScheme(.light)
        }
    }
}
