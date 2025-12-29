import AppIntents
import Flutter

// Available in iOS 16.0+
@available(iOS 16.0, *)
struct SendTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Transaction"
    static var description = IntentDescription("Send a text transaction to Money Tracker.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Text", requestValueDialog: "What do you want to add?")
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult {
        // Get the Flutter controller
        guard let controller = await UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
            return .result(dialog: "Could not connect to the app.")
        }
        
        // Send the text via MethodChannel
        let channel = FlutterMethodChannel(name: "com.moneytracker.siri/text",
                                           binaryMessenger: controller.binaryMessenger)
        
        channel.invokeMethod("receiveTextFromSiri", arguments: text)
        
        return .result(dialog: "Sent to Money Tracker")
    }
}

@available(iOS 16.0, *)
struct MyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendTextIntent(),
            phrases: [
                "Send \(\.$text) to \(.applicationName)",
                "Add transaction to \(.applicationName) \(\.$text)"
            ],
            shortTitle: "Add Transaction",
            systemImageName: "plus.circle"
        )
    }
}
