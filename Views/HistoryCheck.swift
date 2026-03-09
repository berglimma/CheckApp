//
//  HistoriCheck.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 03/12/25.
//

import SwiftUI
import SwiftData

struct HistoricoCheck: View {

    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = HistoricoViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.historico) { item in
                VStack(alignment: .leading, spacing: 6) {

                    Text(item.nomeCliente)
                        .font(.headline)

                    Text("Placa: \(item.placa)")
                        .font(.subheadline)

                    Text("Data: \(viewModel.formatarData(item.data))")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(item.tipo)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            item.tipo == "Devolução"
                            ? Color.orange.opacity(0.2)
                            : Color.green.opacity(0.2)
                        )
                        .cornerRadius(6)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Histórico")
            .task {
                viewModel.carregarHistorico(context: context)
            }
        }
    }
}

#Preview {
    Group {
        HistoricoCheck()
            .preferredColorScheme(.light)
        HistoricoCheck()
            .preferredColorScheme(.dark)
    }
}
