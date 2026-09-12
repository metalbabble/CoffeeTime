import AppKit
import IOKit.pwr_mgt

final class SleepAssertion {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive = false

    func setActive(_ active: Bool) {
        guard active != isActive else { return }

        if active {
            let reason = "CoffeeTime is keeping the Mac awake" as CFString
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &assertionID
            )
            isActive = result == kIOReturnSuccess
        } else {
            release()
        }
    }

    func release() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isActive = false
    }

    deinit {
        release()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let sleepAssertion = SleepAssertion()
    private var window: NSWindow!
    private var statusLabel: NSTextField!
    private var toggle: NSSwitch!

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        sleepAssertion.setActive(true)
        updateStatus()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        sleepAssertion.release()
    }

    private func buildWindow() {
        let contentSize = NSSize(width: 360, height: 190)
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CoffeeTime"
        window.isReleasedWhenClosed = false
        window.center()

        let title = NSTextField(labelWithString: "Keep Mac Awake")
        title.font = .systemFont(ofSize: 22, weight: .semibold)

        let detail = NSTextField(wrappingLabelWithString: "Prevent automatic sleep while CoffeeTime is running.")
        detail.font = .systemFont(ofSize: 13)
        detail.textColor = .secondaryLabelColor

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)

        toggle = NSSwitch()
        toggle.controlSize = .large
        toggle.state = .on
        toggle.target = self
        toggle.action = #selector(toggleChanged(_:))
        toggle.toolTip = "Allow or prevent automatic sleep"

        let stack = NSStackView(views: [title, detail, statusLabel, toggle])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        guard let contentView = window.contentView else { return }
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detail.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            toggle.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 2)
        ])

        window.makeKeyAndOrderFront(nil)
    }

    @objc private func toggleChanged(_ sender: NSSwitch) {
        sleepAssertion.setActive(sender.state == .on)
        updateStatus()
    }

    private func updateStatus() {
        let active = sleepAssertion.isActive
        statusLabel.stringValue = active ? "Sleep prevention is on" : "Sleep prevention is off"
        statusLabel.textColor = active ? .systemGreen : .secondaryLabelColor
        if toggle.state == .on && !active {
            toggle.state = .off
        }
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
