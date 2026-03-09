//
//  Car.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 28/02/26.
//

import SwiftData
import Foundation

@Model
class Car {
    var brand: String
    var model: String
    var plate: String
    var year: Int
    var client: Client?
    
    init(brand: String,
         model: String,
         plate: String,
         year: Int) {
        self.brand = brand
        self.model = model
        self.plate = plate
        self.year = year
    }
}
