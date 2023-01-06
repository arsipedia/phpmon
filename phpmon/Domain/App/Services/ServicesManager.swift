//
//  ServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

class ServicesManager: ObservableObject {

    @ObservedObject static var shared: ServicesManager = ValetServicesManager()

    @Published var serviceWrappers = [ServiceWrapper]()

    public static func useFake() {
        ServicesManager.shared = FakeServicesManager.init(
            formulae: ["php", "nginx", "dnsmasq", "mysql"],
            status: .active
        )
    }

    /**
     The order of services is important, so easy access is accomplished
     without much fanfare through subscripting.
     */
    subscript(name: String) -> ServiceWrapper? {
        return self.serviceWrappers.first { wrapper in
            wrapper.name == name
        }
    }

    public var statusMessage: String {
        if self.serviceWrappers.isEmpty {
            return "Loading..."
        }

        let statuses = self.serviceWrappers[0...2].map { $0.status }

        if statuses.contains(.missing) {
            return "A key service is not installed."
        }
        if statuses.contains(.inactive) {
            return "A key service is not running."
        }

        return "All Valet services are OK."
    }

    public var statusColor: Color {
        if self.serviceWrappers.isEmpty {
            return .yellow
        }

        let statuses = self.serviceWrappers[0...2].map { $0.status }
        if statuses.contains(.missing) {
            return .red
        }
        if statuses.contains(.inactive) {
            return .red
        }

        return .green
    }

    /**
     This method is called when the system configuration has changed
     and all the status of one or more services may need to be determined.
     */
    public func reloadServicesStatus() async {
        fatalError("This method `\(#function)` has not been implemented")
    }

    /**
     This method is called when a service needs to be toggled (on/off).
     */
    public func toggleService(named: String) async {
        fatalError("This method `\(#function)` has not been implemented")
    }

    /**
     This method will notify all publishers that subscribe to notifiable objects.
     The notified objects include this very ServicesManager as well as any individual service instances.
     */
    public func broadcastServicesUpdated() {
        Task { @MainActor in
            self.objectWillChange.send()
        }
    }

    var formulae: [HomebrewFormula] {
        var formulae = [
            Homebrew.Formulae.php,
            Homebrew.Formulae.nginx,
            Homebrew.Formulae.dnsmasq
        ]

        let additionalFormulae = (Preferences.custom.services ?? []).map({ item in
            return HomebrewFormula(item, elevated: false)
        })

        formulae.append(contentsOf: additionalFormulae)

        return formulae
    }

    init() {
        Log.info("The services manager will determine which Valet services exist on this system.")

        serviceWrappers = formulae.map {
            ServiceWrapper(formula: $0)
        }
    }
}
