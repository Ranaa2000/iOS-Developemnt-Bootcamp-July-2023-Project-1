//
//  TodoListAppApp.swift
//  TodoListApp
//
//  Created by Rana MHD on 17/01/1445 AH.
//

import SwiftUI

@main
struct TodoListAppApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
