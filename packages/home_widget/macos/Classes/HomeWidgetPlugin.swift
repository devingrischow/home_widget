import Cocoa
import FlutterMacOS
import Intents
import AppIntents
import WidgetKit


@available(macOS 10.15.4, *)
public class HomeWidgetPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static var groupId: String?

  
  //Needs for Minimum Version
  //WidgetKit macOS minimum 11.0+: https://developer.apple.com/documentation/widgetkit
  //Shared Preferences with Suit Name min; 10.9+: https://developer.apple.com/documentation/Foundation/UserDefaults/init(suiteName:)
  //Widget URL Open From min version; 11.0+: https://developer.apple.com/documentation/swiftui/view/widgeturl(_:)
  //Reload Timelines min; 11.0+, with widgetkit: https://developer.apple.com/documentation/widgetkit/widgetcenter/reloadtimelines(ofkind:)
  // Minimum macOS Widget Version = 11.0+


  //Needs for Minimum Interactible Version:
  //Desktop Widget Minimum Version; 14: https://support.apple.com/guide/mac-help/add-and-customize-widgets-mchl52be5da5/14.0/mac/14.0
  //  -MacOs Sonoma Also introduced fully interactible widgets
  //Widget With Intent Init min version; 14: https://developer.apple.com/documentation/SwiftUI/Button/init(_:intent:)-7urde
  // Minimum Interactible macOS Widget Version: 14.0+



  //Configuration content for home screen mac apps ∏
  //Home screen mac apps were only introduced recently,

  //Configuration Borrowed from ios
  //Limited to macOS version 14.
  //Note: Reasoning: home screen interactable widgets were introduced in that version, 
  //For simple management limit it to that version
  //Configuration Lookup requires WidgetConfigurationIntent[https://developer.apple.com/documentation/appintents/widgetconfigurationintent]
  @available(macOS 14.0, *)
  private static var configurationLookup: [String: any WidgetConfigurationIntent.Type] = [:]

  //Minimum Versiuion Required: 14
  //Note: Reasoning: 
  //Configuration Widgets were introduced in macOS 14
  //Powered With `WidgetConfigurationIntent`, https://developer.apple.com/documentation/appintents/widgetconfigurationintent
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

  //*Constants

  private let notInitializedError = FlutterError(
    code: "-7", message: "AppGroupId not set. Call setAppGroupId first", details: nil
  )

  private let minimumVersionMessage:String = "Widgets are only available on macOS 11.0 and above"
  private let minimumInteractibleWidgetVersion:String = "Widgets with Intents are only available on macOS 14.0 and above"
  //----

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
      print("App NOT running in extension")
      return
    }

    registrar.addApplicationDelegate(instance)

    // Changed: 9/24/25 changed from NSSelector to .addApplicationDelegate 
    //More preformative and should still be capable for all versions that can support the widgets
    // let selector = NSSelectorFromString("addApplicationDelegate:")
    // if registrar.responds(to: selector) {
    //   print("Register Responded")
    //   registrar.perform(selector, with: instance)
    // }else{
    //   print("Failed to Register")
    // }
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
          let preferences = UserDefaults(suiteName: HomeWidgetPlugin.groupId)
          //Only continue if Data is VALID and NOT NULL
          if data != nil {
            //Represent the retrieved data as a retrived flutter type
            if let binaryData = data as? FlutterStandardTypedData {
              print("Basic Binary Set Value for Object: \(binaryData.data)")

              preferences?.set(Data(binaryData.data), forKey: id)
            }else{
              print("Basic Set Value for Object: \(data)")

              preferences?.set(data, forKey: id)
            }
          }else{
            print("Remove Object")
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
        let preferences = UserDefaults(suiteName: HomeWidgetPlugin.groupId)
        let val = preferences?.value(forKey: id) ?? defaultValue
        
        print("Get Widget Values: \(String(describing: val))")
        result(val)
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
      if let myArgs = args as? [String: Any?],
        let name = (myArgs["ios"] ?? myArgs["name"]) as? String
      {
        //Reload Timelines Works with all versions of widgetKit
        //From: https://developer.apple.com/documentation/widgetkit/widgetcenter/reloadtimelines(ofkind:)
        if #available(macOS 11.0, *) {
          #if arch(arm64) || arch(i386) || arch(x86_64)
            WidgetCenter.shared.reloadTimelines(ofKind: name)
            result(true)
          #endif
        } else {
          result(
            FlutterError(
              code: "-4", message: minimumVersionMessage, details: nil)
          )
        }
      }else{
        result(
          FlutterError(
            code: "-3", message: "InvalidArguments updateWidget must be called with name",
            details: nil)
        )
      }
    } else if call.method == "initiallyLaunchedFromHomeWidget" {
      logToFile("Handling Method For initially Launched from Home Widget ---->")
      // Idea: Handle not only home screen widgets with this function,
      // BUT ALSO Notification Center widgets

      //Access NsApplication and get if launched from URL
      
     
      logToFile("Curr InitalURl during Check: \(initialUrl)")
      logToFile("GroupId At InitalURL Check: \(HomeWidgetPlugin.groupId)")

      
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
      result(initialUrl?.absoluteString)
    } else if call.method == "isRequestPinWidgetSupported" {
      //Not available for macOS
      result(false)
    } else if call.method == "requestPinWidget" {
      //Not available for macOS
      result(nil)
    } else if call.method == "getInstalledWidgets" {
      print("Handling Get Installed Widgets ---->")
      //Encompas for minimum version for macOS widgets (notification widgets included, at least until monitoring is no longer possible)

      if #available(macOS 11.0, *) {
        #if arch(arm64) || arch(i386) || arch(x86_64)
          WidgetCenter.shared.getCurrentConfigurations { result2 in
            switch result2 {
            case .success(let widgets):
              print("Widgets Data: \(widgets)")
              let widgetInfoList = widgets.map { widget in
                print("Widget Info: \(widget)")
                var configuration: [String: Any] = [String: Any]()

                //Assigning of Intent 
                //(Mostly mirrors iOS implementation, say for macOS version difference [macos 14 == ios 17 for config introduction])
                var intent: Any?
                if widget.configuration != nil {
                  intent = widget.configuration
                }
                //Handle Widget Interaction from macOS 14+
                //has to be 14+, and if let intent type 
                else if #available(macOS 14.0, *), 
                  let intentType = HomeWidgetPlugin.configurationLookup[widget.kind]
                {
                  intent = widget.widgetConfigurationIntent(of: intentType)
                }

                if let intent = intent {
                  var intentData: [String: Any?] = [:]
                  
                  //Handle interactible widgets/modern intent widgets
                  if #available(macOS 14.0, *),
                    let configurationIntent = intent as? (any WidgetConfigurationIntent)
                  {
                    print("Configuration Intent from WidgetConfigIntent: \(configurationIntent)")
                    let mirror = Mirror(reflecting: configurationIntent)
                    print("Mirror From WidgetConfigurationIntent: \(mirror)")

                    for (name, value) in mirror.children {
                      if let name {
                        intentData[name] = value
                      }
                    }
                  }
                  //Handle normal Configuration Intents
                  else if let configurationIntent = intent as? INIntent {
                    let intentClass: AnyClass = type(of: configurationIntent)

                    var count: UInt32 = 0
                    //Inspect intent class, and use copypropertList with a 32 bit counter to track 
                    //The count of properties
                    if let properties = class_copyPropertyList(intentClass, &count) {
                      //for each property assign it to intentData
                      for i in 0..<count {
                        let property = property_getName(properties[Int(i)])
                        if let propertyName = String(utf8String: property) {

                          let value = configurationIntent.value(forKey: propertyName)
                          intentData[propertyName] = value
                        }

                      }
                      
                      //Class propertylist has to end with freeing the properties
                      free(properties)
                    }
                  }

                  print("Intent Data After Intent Handling: \(intentData)")
                  if !intentData.isEmpty{
                    for (internalPropertyName, rawValue) in intentData {
                      print("internalPropertyName: \(internalPropertyName). RawValue: \(rawValue)")
                      //Handle Formatiing of the various ways propertyName is given
                      let propertyName = 
                      internalPropertyName.hasPrefix("_") == true
                      ? String(internalPropertyName.dropFirst())
                      : internalPropertyName

                      let value: Any?

                      if let intentParameter = rawValue as? _AnyIntentParameter {
                        // Get the wrapped value from the IntentParameter. Used for WidgetConfigurationIntent
                        //Mirror of iOS
                        value = intentParameter.anyWrappedValue
                        //Configuration and values should be identical, both swift/xcode based. only major differences should come from detections/internal handlings
                        //Thats the pattern that has followed so far 
                      }else{
                        // Use rawValue if it is not an IntentParameter
                        value = rawValue 
                        //Helps handle anything else, especially if the widget has nil intents
                      }
                      print("Value Before Being Switched On: \(value)")
                      //The widget configuration is filled from switching on whatever type the value can be cast as
                      switch value{
                        case is NSNull:
                          configuration[propertyName] = NSNull()
                        
                        case let boolValue as Bool:
                          configuration[propertyName] = boolValue

                        case let intValue as Int32:
                          configuration[propertyName] = NSNumber(value: intValue)

                        case let intValue as Int:
                          configuration[propertyName] = NSNumber(value: intValue)

                        case let doubleValue as Double:
                          configuration[propertyName] = NSNumber(value: doubleValue)

                        case let stringValue as String:
                          configuration[propertyName] = stringValue

                        case let dataValue as Data:
                          configuration[propertyName] = FlutterStandardTypedData(bytes: dataValue)
                        
                        case let arrayValue as [Any]:
                          configuration[propertyName] = arrayValue

                        case let dictionaryValue as [String: Any]:
                          configuration[propertyName] = dictionaryValue

                        case let dateValue as Date:
                          let dateFormatter = ISO8601DateFormatter()
                          configuration[propertyName] = dateFormatter.string(from: dateValue)

                        case let urlValue as URL:
                          configuration[propertyName] = urlValue.absoluteString

                        // Handle Codable types by trying to convert to a dictionary
                        case let codableValue as (any Codable):
                          let encoder = JSONEncoder()
                          do {
                            let data = try encoder.encode(codableValue)
                            if let jsonObject = try JSONSerialization.jsonObject(
                              with: data, options: []) as? [String: Any]
                            {
                              configuration[propertyName] = jsonObject
                            }
                          } catch {
                            if let value = value {
                              configuration[propertyName] = "\(value)"
                            } else {
                              configuration[propertyName] = nil
                            }

                          }
                        
                        case let inObject as INObject:
                          configuration[propertyName] = [
                            "identifier": inObject.identifier,
                            "displayString": inObject.displayString,
                          ]

                        default:
                          if let value = value {
                            configuration[propertyName] = "\(value)"
                          } else {
                            configuration[propertyName] = nil
                          }

                      }
                    }
                  }
                  //Bottom of if let Intent 
                }

                var resultMap: [String: Any] = [
                  "family": "\(widget.family)",
                  "kind": widget.kind,
                ]

                if !configuration.isEmpty {
                  resultMap["configuration"] = configuration
                }

                return resultMap

                //Bottom of MAP
              }
              result(widgetInfoList)
            case .failure(let error):
              print("Error from getting installed widgets")
              result(
                FlutterError(
                  code: "-8",
                  message: "Failed to get installed widgets: \(error.localizedDescription)",
                  details: nil
                )
              )
            }
          }
        #endif
      } else {
        result(
            FlutterError(
              code: "-4", message: minimumVersionMessage, details: nil)
          )
      }
    } else {
      result(FlutterMethodNotImplemented)
    }

  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    print("<-- On Listen Called")
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    print("<-- On Cancel Called")
    eventSink = nil
    return nil
  }
  
  //Changed: 9/24/25 Different from the iOS way of opening. 
  // iOS uses https://developer.apple.com/documentation/UIKit/UIApplicationDelegate/application(_:open:options:)
  //This Allows for more easily opening the app from different URLs
  //
  //Function from: https://api.flutter.dev/macos-embedder/protocol_flutter_app_lifecycle_delegate-p.html#aec2ebf324f911ae9b560c2c767a7d594
  //Compiler error for new function name, handleopenurl is changed
  @objc
  public func handleOpen(_ urls: [URL]) -> Bool {
    // Handle the URLs here
    logToFile("Handling Open From Urls: \(urls)")
    //Launch url should be the ONLY item in the array from launch
    let launchURL = urls[0]


    if isWidgetUrl(url: launchURL) {
      logToFile("Passed URL Check, \(launchURL)")
      //Set the latestUrl to the launchedURL
      initialUrl = launchURL
      latestUrl = launchURL
      return true
    }

    return false // or false depending on success
}







  private func isWidgetUrl(url: URL) -> Bool {
    logToFile("Is widgetURl Called. URL given: \(url)")
    let components = URLComponents.init(url: url, resolvingAgainstBaseURL: false)
    logToFile("URL Components: \(components). QueryItems: \(components?.queryItems)")
    
    let result = components?.queryItems?.contains(where: { (item) in item.name == "homeWidget" }) ?? false

    
    logToFile("Result of if url is WidgetURL: \(result)")


    return result
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

// Example: Write to Documents directory
@available(macOS 10.15.4, *)
func logToFile(_ message: String) {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                               in: .userDomainMask)[0]
    let logURL = documentsPath.appendingPathComponent("app_log.txt")
    
    let dateFormat = DateFormatter()
    dateFormat.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let timestamp = dateFormat.string(from: Date())
    let logEntry = "\(timestamp): \(message)\n"
    print("Log Entry: \(logEntry)")
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
