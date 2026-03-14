import AppKit
import SwiftUI

final class VibrancyViewController: NSViewController {

    private let serviceManager: BrewServiceManager
    private let onQuit: () -> Void

    init(serviceManager: BrewServiceManager, onQuit: @escaping () -> Void) {
        self.serviceManager = serviceManager
        self.onQuit = onQuit
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let effect = NSVisualEffectView()
        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        self.view = effect

        let hosting = NSHostingController(
            rootView: MenuBarView(
                serviceManager: serviceManager,
                onQuit: onQuit
            )
        )
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = .clear

        addChild(hosting)
        effect.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: effect.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: effect.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: effect.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: effect.bottomAnchor),
        ])
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var serviceManager = BrewServiceManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mug.fill", accessibilityDescription: "Vrew")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 500)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = VibrancyViewController(
            serviceManager: serviceManager,
            onQuit: { [weak self] in self?.quitApplication() }
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            serviceManager.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func quitApplication() {
        popover.performClose(nil)
        NSApp.terminate(nil)
    }
}
