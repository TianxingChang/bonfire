// Bonfire/BonfireApp.swift
import SwiftUI
import AppKit

@main
struct BonfireApp: App {
    @StateObject private var preferences: Preferences
    @StateObject private var controller: BonfireController

    @Environment(\.openWindow) private var openWindow

    init() {
        let prefs = Preferences()
        let assertion = SystemAssertionManager()
        let power = SystemPowerMonitor()
        let notifier = SystemNotifier()
        let ctrl = BonfireController(
            assertionManager: assertion,
            powerMonitor: power,
            notifier: notifier,
            preferences: prefs
        )
        _preferences = StateObject(wrappedValue: prefs)
        _controller = StateObject(wrappedValue: ctrl)

        notifier.requestAuthorization()
        power.start()
        LaunchAtLogin.setEnabled(prefs.launchAtLogin)
        Self.startTickerLoop(controller: ctrl)
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(controller: controller, preferences: preferences) {
                openWindow(id: "preferences")
            }
        } label: {
            Image(nsImage: controller.state.isBurning
                  ? IconRenderer.burningImage()
                  : IconRenderer.idleImage())
        }
        .menuBarExtraStyle(.window)

        Window("Bonfire Preferences", id: "preferences") {
            PreferencesView(preferences: preferences)
        }
        .windowResizability(.contentSize)
    }

    private static func startTickerLoop(controller: BonfireController) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in controller.tick() }
        }
    }
}
