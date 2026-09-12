import AppKit
import IOKit.pwr_mgt

final class PowerAssertion {
    private let type: CFString
    private let reason: CFString
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive = false

    init(type: CFString, reason: CFString) {
        self.type = type
        self.reason = reason
    }

    func setActive(_ active: Bool) {
        guard active != isActive else { return }

        if active {
            let result = IOPMAssertionCreateWithName(
                type,
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
    private let sleepAssertion = PowerAssertion(
        type: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
        reason: "CoffeeTime is preventing system sleep" as CFString
    )
    private let displayAssertion = PowerAssertion(
        type: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
        reason: "CoffeeTime is keeping the display awake" as CFString
    )
    private var window: NSWindow!
    private var sleepStatusLabel: NSTextField!
    private var displayStatusLabel: NSTextField!
    private var sleepToggle: NSSwitch!
    private var displayToggle: NSSwitch!

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        buildWindow()
        sleepAssertion.setActive(true)
        displayAssertion.setActive(true)
        updateStatus()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        sleepAssertion.release()
        displayAssertion.release()
    }

    private func buildMainMenu() {
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu

        let quitItem = NSMenuItem(
            title: "Quit CoffeeTime",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        appMenu.addItem(quitItem)

        let mainMenu = NSMenu()
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func buildWindow() {
        let contentSize = NSSize(width: 360, height: 240)
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

        sleepStatusLabel = makeStatusLabel()
        displayStatusLabel = makeStatusLabel()

        sleepToggle = makeToggle(action: #selector(sleepToggleChanged(_:)), toolTip: "Allow or prevent automatic sleep")
        displayToggle = makeToggle(action: #selector(displayToggleChanged(_:)), toolTip: "Allow or prevent the display from sleeping or locking")

        let sleepRow = makeRow(title: "Prevent system sleep", statusLabel: sleepStatusLabel, toggle: sleepToggle)
        let displayRow = makeRow(title: "Prevent screen off and lock", statusLabel: displayStatusLabel, toggle: displayToggle)

        let stack = NSStackView(views: [title, detail, sleepRow, displayRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        guard let contentView = window.contentView else { return }
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detail.trailingAnchor.constraint(equalTo: stack.trailingAnchor)
        ])

        window.makeKeyAndOrderFront(nil)
    }

    private func makeStatusLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 13, weight: .medium)
        return label
    }

    private func makeToggle(action: Selector, toolTip: String) -> NSSwitch {
        let toggle = NSSwitch()
        toggle.controlSize = .large
        toggle.state = .on
        toggle.target = self
        toggle.action = action
        toggle.toolTip = toolTip
        return toggle
    }

    private func makeRow(title: String, statusLabel: NSTextField, toggle: NSSwitch) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 14, weight: .medium)

        let row = NSStackView(views: [label, statusLabel, toggle])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        return row
    }

    @objc private func sleepToggleChanged(_ sender: NSSwitch) {
        sleepAssertion.setActive(sender.state == .on)
        updateStatus()
    }

    @objc private func displayToggleChanged(_ sender: NSSwitch) {
        displayAssertion.setActive(sender.state == .on)
        updateStatus()
    }

    private func updateStatus() {
        updateStatusLabel(sleepStatusLabel, toggle: sleepToggle, active: sleepAssertion.isActive, onText: "On", offText: "Off")
        updateStatusLabel(displayStatusLabel, toggle: displayToggle, active: displayAssertion.isActive, onText: "On", offText: "Off")
    }

    private func updateStatusLabel(_ label: NSTextField, toggle: NSSwitch, active: Bool, onText: String, offText: String) {
        label.stringValue = active ? onText : offText
        label.textColor = active ? .systemGreen : .secondaryLabelColor
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
