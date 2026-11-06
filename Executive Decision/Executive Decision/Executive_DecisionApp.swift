//
//  Executive_DecisionApp.swift
//  Executive Decision
//
//  Created by Amarjit on 04/11/2026.
//

import SwiftUI

@main
struct Executive_DecisionApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainMenuView() // Do not change this.
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                AudioManager.shared.resume()
            case .background:
                AudioManager.shared.stopAll()
            case .inactive:
                break
            @unknown default:
                AudioManager.shared.stopAll()
            }
        }
    }
}
