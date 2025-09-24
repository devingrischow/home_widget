import Cocoa
import home_widget
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        
        if #available(macOS 14.0, *) {
          HomeWidgetPlugin.setConfigurationLookup(to: [
            "ConfigurableWidget": ConfigurationAppIntent.self
          ])
        }
        
//        launchIsDefaultUserInfoKey
    }
}
