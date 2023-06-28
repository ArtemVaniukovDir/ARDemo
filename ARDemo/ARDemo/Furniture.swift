//
//  Furniture.swift
//  ARDemo
//
//  Created by Artem Vaniukov on 28.06.2023.
//

import ARKit
import RealityKit

enum Furniture: String, CaseIterable {
    case stool
    case bench
    case clock
    case banana
    case picture
    case goldBar
    
    var name: String {
        rawValue.capitalized
    }
    
    var model: Entity {
        switch self {
        case .stool:
            return try! Experience.loadStool()
        case .bench:
            return try! Experience.loadBench()
        case .clock:
            return try! Experience.loadClock()
        case .banana:
            return try! Experience.loadBanana()
        case .picture:
            return try! Experience.loadPicture()
        case .goldBar:
            return try! Experience.loadGoldBar()
        }
    }
    
    var goal: ARCoachingOverlayView.Goal {
        switch self {
        case .stool:
            return .horizontalPlane
        case .bench:
            return .horizontalPlane
        case .clock:
            return .verticalPlane
        case .banana:
            return .horizontalPlane
        case .picture:
            return .verticalPlane
        case .goldBar:
            return .horizontalPlane
        }
    }
}
