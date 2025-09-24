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
//        launchIsDefaultUserInfoKey
    }
    
//    override func application(_ application: NSApplication, open urls: [URL]) {
//        logToFileLocal("logged Open from URl from DELEGATE. URL: \(urls)")
//    }
//    
    
    
    
    
//    override func applicationDidFinishLaunching(_ notification: Notification) {
////        RegisterGeneratedPlugins(registry: self)
//    }
}


// Example: Write to Documents directory
@available(macOS 10.15.4, *)
func logToFileLocal(_ message: String) {
    let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                               in: .userDomainMask)[0]
    let logURL = documentsPath.appendingPathComponent("app_log.txt")
    
    let dateFormat = DateFormatter()
    dateFormat.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let timestamp = dateFormat.string(from: Date())
    let logEntry = "\(timestamp): \(message)\n"
    
    if let data = logEntry.data(using: .utf8) {
        do{
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                try fileHandle.seekToEnd()
                fileHandle.write(data)
                try fileHandle.close()
            } else {
                // Create new file
                try data.write(to: logURL)
            }
        }catch{
            print("error trying to write to file")
        }
        
                
            
        
        
    }
}
