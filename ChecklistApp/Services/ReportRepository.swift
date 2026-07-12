import Foundation
import SwiftData

@MainActor
enum ReportRepository {
    
    static func save(
        context: ModelContext,
        snapshot: ReportSnapshot
    ) {
        let json = CheckListHistorico.encodeSnapshot(snapshot)
        let historico = CheckListHistorico(
            id: snapshot.id,
            nomeCliente: snapshot.cliente,
            placa: snapshot.placa,
            data: snapshot.dataRegistro,
            tipo: snapshot.tipo,
            ownerId: snapshot.ownerId,
            reportJSON: json,
            horaRegistro: snapshot.horaRegistro,
            funcionario: snapshot.funcionario
        )
        context.insert(historico)
        try? context.save()
    }
    
    static func delete(
        item: CheckListHistorico,
        context: ModelContext
    ) {
        let ownerId = item.ownerId.isEmpty ? item.id.uuidString : item.ownerId
        try? PhotoStore.shared.deleteAll(ownerId: ownerId, context: context)
        context.delete(item)
        try? context.save()
    }
}
