import Foundation
import SwiftData
import UIKit

@Model
final class PhotoAttachment {
    var id: UUID
    var ownerId: String
    var ownerType: String
    var fileName: String
    var createdAt: Date
    var sortOrder: Int
    
    init(
        id: UUID = UUID(),
        ownerId: String,
        ownerType: String,
        fileName: String,
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.ownerId = ownerId
        self.ownerType = ownerType
        self.fileName = fileName
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

enum PhotoOwnerType: String {
    case entrega
    case devolucao
    case troca
    case avaria
    case trator
    case profile
}

@MainActor
final class PhotoStore {
    static let shared = PhotoStore()
    
    private let folderName = "AutoWizePhotos"
    
    private var rootURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    func fileURL(for attachment: PhotoAttachment) -> URL {
        rootURL
            .appendingPathComponent(attachment.ownerId, isDirectory: true)
            .appendingPathComponent(attachment.fileName)
    }
    
    func loadImage(for attachment: PhotoAttachment) -> UIImage? {
        let url = fileURL(for: attachment)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    func loadImages(ownerId: String, context: ModelContext) -> [(PhotoAttachment, UIImage)] {
        let id = ownerId
        let descriptor = FetchDescriptor<PhotoAttachment>(
            predicate: #Predicate { $0.ownerId == id },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        let items = (try? context.fetch(descriptor)) ?? []
        return items.compactMap { att in
            guard let image = loadImage(for: att) else { return nil }
            return (att, image)
        }
    }
    
    @discardableResult
    func insert(
        image: UIImage,
        ownerId: String,
        ownerType: PhotoOwnerType,
        context: ModelContext
    ) throws -> PhotoAttachment {
        let ownerDir = rootURL.appendingPathComponent(ownerId, isDirectory: true)
        try FileManager.default.createDirectory(at: ownerDir, withIntermediateDirectories: true)
        
        let photoId = UUID()
        let fileName = "\(photoId.uuidString).jpg"
        let fileURL = ownerDir.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.82) else {
            throw PhotoStoreError.compressionFailed
        }
        try data.write(to: fileURL, options: .atomic)
        
        let existing = loadImages(ownerId: ownerId, context: context).count
        let attachment = PhotoAttachment(
            id: photoId,
            ownerId: ownerId,
            ownerType: ownerType.rawValue,
            fileName: fileName,
            sortOrder: existing
        )
        context.insert(attachment)
        try context.save()
        return attachment
    }
    
    func replace(
        attachment: PhotoAttachment,
        with image: UIImage,
        context: ModelContext
    ) throws {
        guard let data = image.jpegData(compressionQuality: 0.82) else {
            throw PhotoStoreError.compressionFailed
        }
        let url = fileURL(for: attachment)
        try data.write(to: url, options: .atomic)
        attachment.createdAt = Date()
        try context.save()
    }
    
    func delete(attachment: PhotoAttachment, context: ModelContext) throws {
        let url = fileURL(for: attachment)
        try? FileManager.default.removeItem(at: url)
        context.delete(attachment)
        try context.save()
    }
    
    func deleteAll(ownerId: String, context: ModelContext) throws {
        let id = ownerId
        let descriptor = FetchDescriptor<PhotoAttachment>(
            predicate: #Predicate { $0.ownerId == id }
        )
        let items = (try? context.fetch(descriptor)) ?? []
        for item in items {
            try delete(attachment: item, context: context)
        }
        let dir = rootURL.appendingPathComponent(ownerId, isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
    }
}

enum PhotoStoreError: LocalizedError {
    case compressionFailed
    
    var errorDescription: String? {
        "Não foi possível processar a imagem."
    }
}
