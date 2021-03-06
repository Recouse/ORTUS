//
//  UserDefaults.swift
//  ORTUS
//
//  Created by Firdavs Khaydarov on 06/02/20.
//  Copyright © 2020 Firdavs. All rights reserved.
//

import Foundation

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: AppGroup.default.rawValue)
    
    struct Key<Value> {
        let name: String
        
        public init(_ name: String) {
            self.name = name
        }
    }
    
    func value<Value>(for key: Key<Value>) -> Value? {
      return object(forKey: key.name) as? Value
    }

    func set<Value>(_ value: Value, for key: Key<Value>) {
      set(value, forKey: key.name)
    }

    func removeValue<Value>(for key: Key<Value>) {
      removeObject(forKey: key.name)
    }
}

extension UserDefaults.Key where Value == Bool {
    static let firstInstall = Self("first_install")
    static let showEvents = Self("show_events")
    static let pinCodeSuggestion = Self("pin_code_suggestion")
}

extension UserDefaults.Key where Value == Int {
    static let notificationsCount = Self("notifications_count")
}

extension UserDefaults.Key where Value == String {
    static let appearance = Self("appearance")
}
