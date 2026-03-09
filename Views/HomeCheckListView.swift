import SwiftUI

struct HomeCheckListView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Título da Tela
                HStack {
                    Spacer()
                    Text("Auto Wize")
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .blue : .green)
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    Image(systemName: "car.fill")
                        .font(.system(size: 45))
                        .foregroundColor(colorScheme == .dark ? .blue : .green)
                    Spacer()
                }
                .padding(.top)

                // Itens do Menu
                VStack(spacing: 20) {
                    HomeMenuItem(
                        title: "Checklist Entrega",
                        imageName: "car.fill",
                        destination: ChecklistView(),
                        backgroundColor: .green
                    )

                  HomeMenuItem(
                        title: "Checklist Devolução",
                        imageName: "car.rear.fill",
                        destination: ChecklistDevolucaoView(),
                        backgroundColor: .yellow
                    )
                  

                    HomeMenuItem(
                        title: "Troca Provisória",
                        imageName: "car.2.fill",
                        destination: TrocaProvisoriaView(),
                        backgroundColor: .orange
                    )

                    HomeMenuItem(
                        title: "Avarias",
                        imageName: "car.side.rear.and.collision.and.car.side.front",
                        destination: AvariaCalculator(),
                        backgroundColor: .red
                    )

                    HomeMenuItem(
                        title: "Histórico de Checklists",
                        imageName: "menucard.fill",
                        destination: HistoryCheck(),
                        backgroundColor: .blue
                    )

                    HomeMenuItem(
                        title: "Cadastro Usuários",
                        imageName: "person.circle",
                        destination: AutoWiseCadastro(),
                        backgroundColor: .indigo
                    )
                    
                    HomeMenuItem(
                        title: "Avaliação Trator",
                        imageName:"car.badge.gearshape" ,
                        destination: ChecklistView(),
                        backgroundColor: .yellow
                        
                    )
                }
                .padding(.horizontal)
                .padding(.top)

                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Componente genérico para itens do menu
struct HomeMenuItem<Destination: View>: View {
    let title: String
    let imageName: String
    let destination: Destination
    let backgroundColor: Color

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: imageName)
                    .font(.system(size: 40))
                    .foregroundColor(backgroundColor)

                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(backgroundColor, lineWidth: 2)
            )
        }
    }
}

// Telas de Destino (Exemplos)
struct ChecklistEntradaView: View {
    var body: some View {
        Text("Tela de Checklist de Entrada")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
    }
}

struct CheckDevolucaoView: View {
    var body: some View {
        Text("Tela de Checklist de Devolução")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
    }
}

struct TrocaProvisoriaView: View {
    var body: some View {
        Text("Tela de Troca Provisória")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
    }
}

struct AvariasCalculator: View {
    var body: some View {
        Text("Tela de Avarias")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
    }
}

struct HistoryCheck: View {
    var body: some View {
        Text("Tela de Histórico de Checklists")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
    }
}

struct AutoWiseCadastroView: View {
    var body: some View {
        Text("Tela de Cadastro de Usuários")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
    }
}

// Preview
struct HomeCheckListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeCheckListView()
                .preferredColorScheme(.dark)

            HomeCheckListView()
                .preferredColorScheme(.light)
        }
    }
}
