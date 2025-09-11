import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
      
    //Plugin Register Location
      
    RegisterGeneratedPlugins(registry: flutterViewController)
      
    //Todo Note: For interactibility home widget capabilities, Restrict it to the minimum version for homescreen widget interactions
      

    super.awakeFromNib()
  }
}
