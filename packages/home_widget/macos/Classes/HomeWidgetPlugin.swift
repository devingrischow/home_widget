import Cocoa
import FlutterMacOS
import Intents
import AppIntents
import WidgetKit


let minimumVersionMessage = "Widgets are only available on macOS 14.0 and above"


public class HomeWidgetPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static var groupId: String?

  //Configuration content for home screen mac apps ∏
  //Home screen mac apps were only introduced recently,

  //Configuration Borrowed from ios, limited to macOS version 14.
  //Reasoning: home screen interactable widgets were introduced in that version, 
  //For simple management limit it to that version
  @available(macOS 14.0, *)
  private static var configurationLookup: [String: any WidgetConfigurationIntent.Type] = [:]

  @available(macOS 14.0, *)
  public static func setConfigurationLookup(
    to configuration: [String: any WidgetConfigurationIntent.Type]
  ) {
    configurationLookup = configuration
  }

  private var initialUrl: URL?
  private var latestUrl: URL? {
    didSet {
      if latestUrl != nil {
        eventSink?.self(latestUrl?.absoluteString)
      }
    }
  }

  private var eventSink: FlutterEventSink?

  private let notInitializedError = FlutterError(
    code: "-7", message: "AppGroupId not set. Call setAppGroupId first", details: nil
  )

  private static func isRunningInAppExtension() -> Bool {
    let bundleURL = Bundle.main.bundleURL
    let bundlePathExtension = bundleURL.pathExtension
    return bundlePathExtension == "appex"
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    print("<-- Register Mac Function Called")

    let instance = HomeWidgetPlugin()
    //Registrar Flutter macOS vs iOS
    //macOS: https://api.flutter.dev/macos-embedder/protocol_flutter_plugin_registrar-p.html
    //iOS: https://api.flutter.dev/ios-embedder/protocol_flutter_plugin_registrar-p.html
    //iOS uses methods for retriving values, meanwhile macOS uses properties
    let channel = FlutterMethodChannel(name: "home_widget", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(
      name: "home_widget/updates", binaryMessenger: registrar.messenger)
    eventChannel.setStreamHandler(instance)
    
    guard isRunningInAppExtension() == false else {
      return
    }

    let selector = NSSelectorFromString("addApplicationDelegate:")
    if registrar.responds(to: selector) {
      registrar.perform(selector, with: instance)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("<-- Handle called with method \(call.method)")
    
    if call.method == "setAppGroupId" {
      print("Handling Method Set Group ID ---->")

      guard let args = call.arguments else {
        return
      }

      print("Retrieved Args: \(args)")

      if let myArgs = args as? [String: Any?],
        let groupId = myArgs["groupId"] as? String
      {
        HomeWidgetPlugin.groupId = groupId
        result(true)
      } else {
        result(
          FlutterError(
            code: "-6", message: "InvalidArguments setAppGroupId must be called with a group id",
            details: nil))
      }

    } else if call.method == "saveWidgetData" {
      print("Handling Method Save Widget Data ---->")
      if HomeWidgetPlugin.groupId == nil {
        result(notInitializedError)
        return
      }
      guard let args = call.arguments else {
        return
      }
      print("Save Args: \(args)")
      if let myArgs = args as? [String:Any?],
        let id = myArgs["id"] as? String,
        let data = myArgs["data"]
        {
          //Data Retrieved from stored preferences
          let preferences = UserDefaults.init(suiteName: HomeWidgetPlugin.groupId)
          //Only continue if Data is VALID and NOT NULL
          if data != nil {
            //Represent the retrieved data as a retrived flutter type
            if let binaryData = data as? FlutterStandardTypedData {
              preferences?.setValue(Data(binaryData.data), forKey: id)
            }else{
              preferences?.setValue(data, forKey: id)
            }
          }else{
            preferences?.removeObject(forKey: id)
          }
          result(true)
        }else{
          result(
          FlutterError(
            code: "-1", message: "InvalidArguments saveWidgetData must be called with id and data",
            details: nil))
        }

    }else if call.method == "getWidgetData" {
      print("Handling Get Widget Data ---->")
      if HomeWidgetPlugin.groupId == nil {
        result(notInitializedError)
        return
      }
      guard let args = call.arguments else {
        return
      }
      print("Get Widget Data Args: \(args)")
      if let myArgs = args as? [String: Any?],
        let id = myArgs["id"] as? String,
        let defaultValue = myArgs["defaultValue"]
      {
        let preferences = UserDefaults.init(suiteName: HomeWidgetPlugin.groupId)
        result(preferences?.value(forKey: id) ?? defaultValue)
      }else{
        result(
          FlutterError(
            code: "-2", message: "InvalidArguments getWidgetData must be called with id",
            details: nil)
        )
      }

    }else if call.method == "updateWidget" {
      print("Handling Update Widget Data ---->")
      guard let args = call.arguments else {
        return
      }
      print("Update args: \(args).")



    } else if call.method == "initiallyLaunchedFromHomeWidget" {
      print("Handling Method For initially Launched from Home Widget ---->")
      // Idea: Handle not only home screen widgets with this function,
      // BUT ALSO Notification Center widgets
      if HomeWidgetPlugin.groupId == nil {
        result(notInitializedError)
        return
      }
      result(initialUrl?.absoluteString)
    } else if call.method == "registerBackgroundCallback" {
      print("Handling method for register background callback ---->")
      if HomeWidgetPlugin.groupId == nil {
        result(notInitializedError)
        return
      }

    } else if call.method == "isRequestPinWidgetSupported" {
      //Not for macOS
      result(false)
    } else if call.method == "requestPinWidget" {
      //Not for macOS
      result(nil)
    } else if call.method == "getInstalledWidgets" {
      print("Handling Get Installed Widgets ---->")

      //Encompas for minimum version for macOS widgets (notification widgets included, at least until monitoring is no longer possible)

    } else {
      result(FlutterMethodNotImplemented)
    }

  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    print("<-- On List Called")
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    print("<-- On Cancel Called")
    eventSink = nil
    return nil
  }

  //Multiple Handlers for application(s)
  public func application(_ application: NSApplication, open urls: [URL]) {
      print("Application Handed Urls: \(urls)")
  }
    
  public func applicationDidFinishLaunching(_ notification: Notification) {
      // notification.userInfo is usually empty/nil for widget launches
      // This just tells you the app finished launching, not WHY
      print("App launched")
      // The notification doesn't contain widget info
   }

  
  
//  public func application(
//    _ application: NSApplication,
//    didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
//  ) -> Bool {
//    print("<--- Application called")
//      NSApplication.userinfo
//    let launchUrl = (launchOptions[UIApplication.LaunchOptionsKey.url] as? NSURL)?.absoluteURL
//    if launchUrl != nil && isWidgetUrl(url: launchUrl!) {
//      initialUrl = launchUrl?.absoluteURL
//      latestUrl = initialUrl
//    }
//    return true
//  }
//
//  public func application(
//    _ application: UIApplication, open url: URL,
//    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
//  ) -> Bool {
//    print("<--- Application called: URL given: \(url)")
//
//    if isWidgetUrl(url: url) {
//      latestUrl = url
//      return true
//    }
//    return false
//  }

  private func isWidgetUrl(url: URL) -> Bool {
    print("Is widgetURl Called. URL given: \(url)")
    let components = URLComponents.init(url: url, resolvingAgainstBaseURL: false)
    return components?.queryItems?.contains(where: { (item) in item.name == "homeWidget" }) ?? false
  }









  // public static func register(with registrar: FlutterPluginRegistrar) {
  //   let channel = FlutterMethodChannel(name: "home_widget", binaryMessenger: registrar.messenger)
  //   let instance = HomeWidgetPlugin()
  //   registrar.addMethodCallDelegate(instance, channel: channel)
  // }

  // public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
  //   switch call.method {
  //   case "getPlatformVersion":
  //     result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
  //   default:
  //     result(FlutterMethodNotImplemented)
  //   }
  // }



  
}

protocol _AnyIntentParameter {

  var anyWrappedValue: Any { get }
}


//Iteration 1 Note: Currently no Exclusion given for no reason given needed here
//Intent Parameter is only available to macOS 13+
//For simplification, only modern widgets get access to the intent parameter (Subject to change during testing)
@available(macOS 14.0, *)
extension IntentParameter: _AnyIntentParameter {
  var anyWrappedValue: Any {
    return wrappedValue
  }
}
