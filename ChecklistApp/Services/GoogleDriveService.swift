//
//  GoogleDriveService.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import UIKit

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

struct GoogleDriveUploadResult {
    let fileId: String
    let webViewLink: URL?
    let fileName: String
}

struct GoogleDriveFile: Identifiable, Hashable {
    let id: String
    let name: String
    let createdTime: Date
    let modifiedTime: Date
    let webViewLink: URL?
    let sizeBytes: Int64?
    
    /// Tipo extraído do nome `AutoWize_Tipo_Cliente_yyyyMMdd_HHmm.pdf`
    var inferredTipo: String {
        let parts = name
            .replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
            .split(separator: "_")
            .map(String.init)
        guard parts.count >= 2, parts[0].caseInsensitiveCompare("AutoWize") == .orderedSame else {
            return "PDF"
        }
        return parts[1]
    }
    
    var inferredCliente: String {
        let parts = name
            .replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
            .split(separator: "_")
            .map(String.init)
        // AutoWize_Tipo_Cliente..._yyyyMMdd_HHmm
        guard parts.count >= 4, parts[0].caseInsensitiveCompare("AutoWize") == .orderedSame else {
            return name
        }
        let middle = parts.dropFirst(2).dropLast(2)
        let client = middle.joined(separator: " ").replacingOccurrences(of: "_", with: " ")
        return client.isEmpty ? name : client
    }
    
    /// Data preferencial para agrupamento (stamp do nome, senão createdTime).
    var sortDate: Date {
        if let stamped = Self.parseStamp(from: name) {
            return stamped
        }
        return createdTime
    }
    
    private static func parseStamp(from fileName: String) -> Date? {
        let base = fileName.replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
        let parts = base.split(separator: "_").map(String.init)
        guard parts.count >= 2 else { return nil }
        let stamp = parts.suffix(2).joined(separator: "_")
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd_HHmm"
        return formatter.date(from: stamp)
    }
}

struct GoogleDriveDayGroup: Identifiable {
    let id: String
    let day: Date
    let files: [GoogleDriveFile]
    
    var title: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, dd 'de' MMMM 'de' yyyy"
        return formatter.string(from: day).capitalized
    }
}

enum GoogleDriveError: LocalizedError {
    case firebaseNotConfigured
    case googleSignInUnavailable
    case noPresenter
    case cancelled
    case missingAccessToken
    case folderFailed
    case uploadFailed(String)
    case listFailed(String)
    case invalidPDF
    
    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase/Google não configurado. Verifique o GoogleService-Info.plist."
        case .googleSignInUnavailable:
            return "Google Sign-In indisponível neste build."
        case .noPresenter:
            return "Não foi possível abrir o login do Google."
        case .cancelled:
            return "Operação no Google Drive cancelada."
        case .missingAccessToken:
            return "Não foi possível obter permissão do Google Drive."
        case .folderFailed:
            return "Não foi possível criar/abrir a pasta no Drive."
        case .uploadFailed(let detail):
            return "Falha ao enviar o PDF: \(detail)"
        case .listFailed(let detail):
            return "Falha ao buscar relatórios no Drive: \(detail)"
        case .invalidPDF:
            return "Arquivo PDF inválido."
        }
    }
}

/// Envio e busca de PDFs no Google Drive (escopo drive.file).
@MainActor
enum GoogleDriveService {
    static let folderName = "Auto Wize Relatórios"
    static let driveFileScope = "https://www.googleapis.com/auth/drive.file"
    
    /// Gera o PDF (se necessário) e faz upload para a pasta do Auto Wize no Drive.
    static func uploadPDF(
        fileURL: URL,
        preferredName: String? = nil,
        presenting viewController: UIViewController? = nil
    ) async throws -> GoogleDriveUploadResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw GoogleDriveError.invalidPDF
        }
        
        let presenter = viewController ?? Self.topViewController()
        guard let presenter else { throw GoogleDriveError.noPresenter }
        
        let token = try await requestDriveAccessToken(presenting: presenter)
        let folderId = try await ensureReportsFolder(accessToken: token)
        
        let fileName = preferredName
            ?? fileURL.lastPathComponent
            .replacingOccurrences(of: " ", with: "_")
        
        return try await uploadFile(
            accessToken: token,
            folderId: folderId,
            fileURL: fileURL,
            fileName: fileName.hasSuffix(".pdf") ? fileName : "\(fileName).pdf"
        )
    }
    
    /// Lista PDFs da pasta Auto Wize, com busca opcional por nome, ordenados por data (mais recente primeiro).
    static func listReports(
        searchQuery: String = "",
        presenting viewController: UIViewController? = nil
    ) async throws -> [GoogleDriveFile] {
        let presenter = viewController ?? Self.topViewController()
        guard let presenter else { throw GoogleDriveError.noPresenter }
        
        let token = try await requestDriveAccessToken(presenting: presenter)
        let folderId = try await ensureReportsFolder(accessToken: token)
        return try await fetchPDFFiles(
            accessToken: token,
            folderId: folderId,
            searchQuery: searchQuery
        )
    }
    
    /// Agrupa arquivos por dia civil (mais recente primeiro).
    static func groupByDay(_ files: [GoogleDriveFile]) -> [GoogleDriveDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: files) { file -> Date in
            calendar.startOfDay(for: file.sortDate)
        }
        
        return grouped
            .map { day, dayFiles in
                let dayId: String = {
                    let f = DateFormatter()
                    f.calendar = Calendar.current
                    f.locale = Locale(identifier: "en_US_POSIX")
                    f.dateFormat = "yyyy-MM-dd"
                    return f.string(from: day)
                }()
                return GoogleDriveDayGroup(
                    id: dayId,
                    day: day,
                    files: dayFiles.sorted { $0.sortDate > $1.sortDate }
                )
            }
            .sorted { $0.day > $1.day }
    }
    
    // MARK: - Auth
    
    private static func requestDriveAccessToken(presenting viewController: UIViewController) async throws -> String {
        #if canImport(GoogleSignIn) && canImport(FirebaseCore)
        AuthService.shared.configureIfNeeded()
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw GoogleDriveError.firebaseNotConfigured
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        do {
            if let user = GIDSignIn.sharedInstance.currentUser {
                let granted = user.grantedScopes ?? []
                let hasDrive = granted.contains { $0.contains("drive.file") || $0.contains("drive") }
                if hasDrive {
                    try await user.refreshTokensIfNeeded()
                    return user.accessToken.tokenString
                }
                
                let scoped = try await user.addScopes([driveFileScope], presenting: viewController)
                try await scoped.user.refreshTokensIfNeeded()
                return scoped.user.accessToken.tokenString
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController,
                hint: nil,
                additionalScopes: [driveFileScope]
            )
            try await result.user.refreshTokensIfNeeded()
            return result.user.accessToken.tokenString
        } catch {
            let ns = error as NSError
            if ns.domain == "com.google.GIDSignIn", ns.code == -5 {
                throw GoogleDriveError.cancelled
            }
            throw error
        }
        #else
        throw GoogleDriveError.googleSignInUnavailable
        #endif
    }
    
    // MARK: - Drive API
    
    private static func ensureReportsFolder(accessToken: String) async throws -> String {
        let query = "name='\(folderName)' and mimeType='application/vnd.google-apps.folder' and trashed=false"
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "spaces", value: "drive"),
            URLQueryItem(name: "fields", value: "files(id,name)")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GoogleDriveError.folderFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let files = json["files"] as? [[String: Any]],
           let first = files.first,
           let id = first["id"] as? String {
            return id
        }
        
        return try await createFolder(accessToken: accessToken, name: folderName)
    }
    
    private static func createFolder(accessToken: String, name: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files?fields=id,name")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String else {
            throw GoogleDriveError.folderFailed
        }
        return id
    }
    
    private static func fetchPDFFiles(
        accessToken: String,
        folderId: String,
        searchQuery: String
    ) async throws -> [GoogleDriveFile] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let escaped = escapeDriveQuery(trimmed)
        
        var queryParts = [
            "'\(folderId)' in parents",
            "mimeType='application/pdf'",
            "trashed=false"
        ]
        if !escaped.isEmpty {
            queryParts.append("name contains '\(escaped)'")
        }
        
        var all: [GoogleDriveFile] = []
        var pageToken: String?
        
        repeat {
            var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
            var items: [URLQueryItem] = [
                URLQueryItem(name: "q", value: queryParts.joined(separator: " and ")),
                URLQueryItem(name: "spaces", value: "drive"),
                URLQueryItem(name: "orderBy", value: "createdTime desc"),
                URLQueryItem(name: "pageSize", value: "100"),
                URLQueryItem(
                    name: "fields",
                    value: "nextPageToken,files(id,name,createdTime,modifiedTime,webViewLink,size,mimeType)"
                )
            ]
            if let pageToken {
                items.append(URLQueryItem(name: "pageToken", value: pageToken))
            }
            components.queryItems = items
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw GoogleDriveError.listFailed("Sem resposta do servidor.")
            }
            
            guard (200...299).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                let detail = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                throw GoogleDriveError.listFailed(detail)
            }
            
            let filesJSON = (json["files"] as? [[String: Any]]) ?? []
            all.append(contentsOf: filesJSON.compactMap(parseDriveFile))
            pageToken = json["nextPageToken"] as? String
        } while pageToken != nil
        
        return all.sorted { $0.sortDate > $1.sortDate }
    }
    
    private static func parseDriveFile(_ json: [String: Any]) -> GoogleDriveFile? {
        guard let id = json["id"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        
        let created = parseRFC3339(json["createdTime"] as? String) ?? Date.distantPast
        let modified = parseRFC3339(json["modifiedTime"] as? String) ?? created
        let link = (json["webViewLink"] as? String).flatMap(URL.init(string:))
        let size: Int64?
        if let sizeString = json["size"] as? String {
            size = Int64(sizeString)
        } else if let sizeNumber = json["size"] as? NSNumber {
            size = sizeNumber.int64Value
        } else {
            size = nil
        }
        
        return GoogleDriveFile(
            id: id,
            name: name,
            createdTime: created,
            modifiedTime: modified,
            webViewLink: link,
            sizeBytes: size
        )
    }
    
    private static func parseRFC3339(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: value) { return date }
        
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }
    
    private static func escapeDriveQuery(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }
    
    private static func uploadFile(
        accessToken: String,
        folderId: String,
        fileURL: URL,
        fileName: String
    ) async throws -> GoogleDriveUploadResult {
        let pdfData = try Data(contentsOf: fileURL)
        guard !pdfData.isEmpty else { throw GoogleDriveError.invalidPDF }
        
        let boundary = "AutowizeBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        var body = Data()
        
        let metadata: [String: Any] = [
            "name": fileName,
            "parents": [folderId],
            "mimeType": "application/pdf"
        ]
        let metadataJSON = try JSONSerialization.data(withJSONObject: metadata)
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n")
        body.append(metadataJSON)
        body.append("\r\n--\(boundary)\r\n")
        body.append("Content-Type: application/pdf\r\n\r\n")
        body.append(pdfData)
        body.append("\r\n--\(boundary)--\r\n")
        
        var request = URLRequest(
            url: URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink")!
        )
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleDriveError.uploadFailed("Sem resposta do servidor.")
        }
        
        guard (200...299).contains(http.statusCode),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fileId = json["id"] as? String else {
            let detail = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw GoogleDriveError.uploadFailed(detail)
        }
        
        let link = (json["webViewLink"] as? String).flatMap(URL.init(string:))
        return GoogleDriveUploadResult(fileId: fileId, webViewLink: link, fileName: fileName)
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

private extension GoogleDriveService {
    static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
