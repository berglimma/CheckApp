//
//  PasswordHasher.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import CryptoKit

enum PasswordHasher {
    private static let pepper = "AutoWize.v1.local"
    
    /// Gera hash SHA-256 com pepper do app (não armazena senha em texto puro).
    static func hash(_ password: String) -> String {
        let payload = Data((pepper + password).utf8)
        return SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
    }
    
    /// Valida senha contra hash ou legado em texto puro.
    static func verify(_ password: String, against stored: String) -> Bool {
        if stored == hash(password) { return true }
        // Migração: contas antigas com senha em texto puro
        if !isHashed(stored), stored == password { return true }
        return false
    }
    
    /// Indica se o valor armazenado precisa ser migrado para hash.
    static func needsRehash(_ stored: String) -> Bool {
        !isHashed(stored)
    }
    
    static func isHashed(_ value: String) -> Bool {
        value.count == 64 && value.allSatisfy(\.isHexDigit)
    }
}
