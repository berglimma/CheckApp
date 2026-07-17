//
//  VehicleCatalog.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI

enum VehicleCategory: String, CaseIterable, Identifiable, Codable {
    case sedan = "Sedan"
    case hatch = "Hatch"
    case suv = "SUV"
    case pickup = "Pickup"
    case tractor = "Trator"
    
    var id: String { rawValue }
    
    var imageName: String {
        switch self {
        case .sedan: return "vehicle_sedan"
        case .hatch: return "vehicle_hatch"
        case .suv: return "vehicle_suv"
        case .pickup: return "vehicle_pickup"
        case .tractor: return "vehicle_tractor"
        }
    }
    
    var systemImage: String {
        switch self {
        case .sedan, .hatch: return "car.side.fill"
        case .suv: return "suv.side.fill"
        case .pickup: return "truck.pickup.side.fill"
        case .tractor: return "leaf.fill"
        }
    }
}

struct VehicleBrand: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let colorHex: UInt
    let kind: Kind
    let models: [VehicleModel]
    
    enum Kind: String {
        case car
        case tractor
    }
    
    var logoImageName: String {
        "logo_\(id)"
    }
    
    var color: Color {
        Color(
            red: Double((colorHex >> 16) & 0xFF) / 255,
            green: Double((colorHex >> 8) & 0xFF) / 255,
            blue: Double(colorHex & 0xFF) / 255
        )
    }
}

struct VehicleModel: Identifiable, Hashable {
    let id: String
    let name: String
    let category: VehicleCategory
    
    init(name: String, category: VehicleCategory) {
        self.id = "\(name)-\(category.rawValue)"
        self.name = name
        self.category = category
    }
}

enum VehicleCatalog {
    
    static let carBrands: [VehicleBrand] = [
        VehicleBrand(
            id: "volkswagen",
            name: "Volkswagen",
            symbol: "v.circle.fill",
            colorHex: 0x1A6DB5,
            kind: .car,
            models: [
                .init(name: "Gol", category: .hatch),
                .init(name: "Polo", category: .hatch),
                .init(name: "Virtus", category: .sedan),
                .init(name: "Nivus", category: .suv),
                .init(name: "T-Cross", category: .suv),
                .init(name: "Saveiro", category: .pickup)
            ]
        ),
        VehicleBrand(
            id: "fiat",
            name: "Fiat",
            symbol: "f.circle.fill",
            colorHex: 0xC8102E,
            kind: .car,
            models: [
                .init(name: "Argo", category: .hatch),
                .init(name: "Mobi", category: .hatch),
                .init(name: "Cronos", category: .sedan),
                .init(name: "Pulse", category: .suv),
                .init(name: "Fastback", category: .suv),
                .init(name: "Strada", category: .pickup),
                .init(name: "Toro", category: .pickup)
            ]
        ),
        VehicleBrand(
            id: "chevrolet",
            name: "Chevrolet",
            symbol: "c.circle.fill",
            colorHex: 0xD4A017,
            kind: .car,
            models: [
                .init(name: "Onix", category: .hatch),
                .init(name: "Onix Plus", category: .sedan),
                .init(name: "Tracker", category: .suv),
                .init(name: "Spin", category: .suv),
                .init(name: "S10", category: .pickup),
                .init(name: "Montana", category: .pickup)
            ]
        ),
        VehicleBrand(
            id: "toyota",
            name: "Toyota",
            symbol: "t.circle.fill",
            colorHex: 0xEB0A1E,
            kind: .car,
            models: [
                .init(name: "Corolla", category: .sedan),
                .init(name: "Yaris", category: .hatch),
                .init(name: "Corolla Cross", category: .suv),
                .init(name: "SW4", category: .suv),
                .init(name: "Hilux", category: .pickup)
            ]
        ),
        VehicleBrand(
            id: "hyundai",
            name: "Hyundai",
            symbol: "h.circle.fill",
            colorHex: 0x002C5F,
            kind: .car,
            models: [
                .init(name: "HB20", category: .hatch),
                .init(name: "HB20S", category: .sedan),
                .init(name: "Creta", category: .suv),
                .init(name: "Tucson", category: .suv)
            ]
        ),
        VehicleBrand(
            id: "jeep",
            name: "Jeep",
            symbol: "j.circle.fill",
            colorHex: 0x3D5C3A,
            kind: .car,
            models: [
                .init(name: "Renegade", category: .suv),
                .init(name: "Compass", category: .suv),
                .init(name: "Commander", category: .suv)
            ]
        ),
        VehicleBrand(
            id: "honda",
            name: "Honda",
            symbol: "h.circle.fill",
            colorHex: 0xCC0000,
            kind: .car,
            models: [
                .init(name: "City", category: .sedan),
                .init(name: "Civic", category: .sedan),
                .init(name: "HR-V", category: .suv),
                .init(name: "WR-V", category: .suv)
            ]
        ),
        VehicleBrand(
            id: "nissan",
            name: "Nissan",
            symbol: "n.circle.fill",
            colorHex: 0xC3002F,
            kind: .car,
            models: [
                .init(name: "Versa", category: .sedan),
                .init(name: "Kicks", category: .suv),
                .init(name: "Frontier", category: .pickup)
            ]
        ),
        VehicleBrand(
            id: "renault",
            name: "Renault",
            symbol: "r.circle.fill",
            colorHex: 0xFFCC33,
            kind: .car,
            models: [
                .init(name: "Kwid", category: .hatch),
                .init(name: "Logan", category: .sedan),
                .init(name: "Duster", category: .suv),
                .init(name: "Oroch", category: .pickup)
            ]
        ),
        VehicleBrand(
            id: "ford",
            name: "Ford",
            symbol: "f.circle.fill",
            colorHex: 0x003478,
            kind: .car,
            models: [
                .init(name: "Ka", category: .hatch),
                .init(name: "Territory", category: .suv),
                .init(name: "Ranger", category: .pickup),
                .init(name: "Maverick", category: .pickup)
            ]
        )
    ]
    
    static let tractorBrands: [VehicleBrand] = [
        VehicleBrand(
            id: "john_deere",
            name: "John Deere",
            symbol: "leaf.circle.fill",
            colorHex: 0x367C2B,
            kind: .tractor,
            models: [
                .init(name: "5075E", category: .tractor),
                .init(name: "6110J", category: .tractor),
                .init(name: "7230J", category: .tractor),
                .init(name: "8R 340", category: .tractor)
            ]
        ),
        VehicleBrand(
            id: "massey",
            name: "Massey Ferguson",
            symbol: "m.circle.fill",
            colorHex: 0xC8102E,
            kind: .tractor,
            models: [
                .init(name: "4275", category: .tractor),
                .init(name: "6713", category: .tractor),
                .init(name: "7719", category: .tractor),
                .init(name: "8700 S", category: .tractor)
            ]
        ),
        VehicleBrand(
            id: "new_holland",
            name: "New Holland",
            symbol: "n.circle.fill",
            colorHex: 0x0055A5,
            kind: .tractor,
            models: [
                .init(name: "TL75", category: .tractor),
                .init(name: "T6.180", category: .tractor),
                .init(name: "T7.245", category: .tractor),
                .init(name: "T8.410", category: .tractor)
            ]
        ),
        VehicleBrand(
            id: "valtra",
            name: "Valtra",
            symbol: "v.circle.fill",
            colorHex: 0xE87722,
            kind: .tractor,
            models: [
                .init(name: "A750", category: .tractor),
                .init(name: "BH180", category: .tractor),
                .init(name: "S374", category: .tractor)
            ]
        ),
        VehicleBrand(
            id: "case_ih",
            name: "Case IH",
            symbol: "c.circle.fill",
            colorHex: 0xC8102E,
            kind: .tractor,
            models: [
                .init(name: "Farmall 80", category: .tractor),
                .init(name: "Maxxum 150", category: .tractor),
                .init(name: "Puma 230", category: .tractor)
            ]
        ),
        VehicleBrand(
            id: "ls_tractor",
            name: "LS Tractor",
            symbol: "l.circle.fill",
            colorHex: 0x1B4F72,
            kind: .tractor,
            models: [
                .init(name: "U60", category: .tractor),
                .init(name: "R50", category: .tractor),
                .init(name: "XJ25", category: .tractor)
            ]
        )
    ]
    
    static func brands(for kind: VehicleBrand.Kind) -> [VehicleBrand] {
        kind == .car ? carBrands : tractorBrands
    }
    
    static func brand(named name: String, kind: VehicleBrand.Kind) -> VehicleBrand? {
        brands(for: kind).first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
