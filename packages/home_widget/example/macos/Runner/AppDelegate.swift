import Cocoa
import FlutterMacOS
import home_widget

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        
    }
    
}
