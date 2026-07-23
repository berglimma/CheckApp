//
//  DocumentFormatter.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 23/07/26.
//

import Foundation

   // "." NO CPF
enum DocumentFormatter {
    static func cpf(_ texto: String) -> String {
        let numeros = String(texto.filter(\.isNumber).prefix(11))
        var resultado = ""

        for (indice, numero) in numeros.enumerated() {
            if indice == 3 || indice == 6 {
                resultado.append(".")
            } else if indice == 9 {
                resultado.append("-")
            }
            resultado.append(numero)
        }

        return resultado
    }
}
