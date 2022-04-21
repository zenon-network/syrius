import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
    print("applicationShouldTerminate")

    let controller: FlutterViewController = NSApp.windows.first?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "window_manager", binaryMessenger: controller.engine.binaryMessenger)

    let args: NSDictionary = [
      "eventName": "close",
    ]
    channel.invokeMethod("onEvent", arguments: args, result: nil)

    return .terminateCancel
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    return true
  }
}