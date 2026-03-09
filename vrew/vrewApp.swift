//
//  vrewApp.swift
//  vrew
//
//  Created by David Noreña on 9/03/26.
//

import SwiftUI

@main
struct vrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
