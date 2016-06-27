//
//  CallbackURLKit.swift
//  CallbackURLKit
/*
The MIT License (MIT)
Copyright (c) 2015 Eric Marchand (phimage)
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Foundation


// action ie. url path
public typealias Action = String
// block which handle action and optionally respond to callback
public typealias ActionHandler = (Parameters, SuccessCallback, FailureCallback, CancelCallback) -> Void
// Simple dictionary for parameters
public typealias Parameters = [String: String]

// Callback for response
public typealias SuccessCallback = (Parameters?) -> Void
public typealias FailureCallback = (FailureCallbackErrorType) -> Void
public typealias CancelCallback = () -> Void


// MARK: global functions


// Perform an action on client application
// - Parameter action: The action to perform.
// - Parameter URLScheme: The URLScheme for application to apply action.
// - Parameter parameters: Optional parameters for the action.
// - Parameter onSuccess: callback for success.
// - Parameter onFailure: callback for failure.
// - Parameter onCancel: callback for cancel.
//
// Throws: CallbackURLKitError
public func performAction(action: Action, URLScheme: String, parameters: Parameters = [:],
    onSuccess: SuccessCallback? = nil, onFailure: FailureCallback? = nil, onCancel: CancelCallback? = nil) throws {
        try Manager.performAction(action, URLScheme: URLScheme, parameters: parameters, onSuccess: onSuccess, onFailure: onFailure, onCancel: onCancel)
}

public func registerAction(action: Action, actionHandler: ActionHandler) {
    Manager.sharedInstance[action] = actionHandler
}

// MARK: - ErrorType
// Implement this protocol to custom the error into Client
public protocol FailureCallbackErrorType: ErrorType {
    var code: Int {get}
    var message: String {get}
}
extension FailureCallbackErrorType {
    public var XCUErrorParameters: Parameters  {
        return [kXCUErrorCode: "\(self.code)", kXCUErrorMessage: self.message]
    }
    public var XCUErrorQuery: String {
        return XCUErrorParameters.query
    }
}

public struct Error {
    public static let Domain = "CallbackURLKit.error"
    
    /// The custom error codes generated by Alamofire.
    public enum Code: Int {
        case NotSupportedAction = 1 // "(action) not supported by (appName)"
        case MissingParameter   = 2 // when handling an action, could return an error to show that parameters are missing
        case MissingErrorCode   = 3
    }

    public static func errorWithCode(code: Code, failureReason: String) -> NSError {
        return errorWithCode(code.rawValue, failureReason: failureReason)
    }
    public static func errorWithCode(code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: Domain, code: code, userInfo: userInfo)
    }
}

extension NSError: FailureCallbackErrorType {
    public var message: String { return localizedDescription }
}

// Framework errors
public enum CallbackURLKitError : ErrorType {
    // It's seems that application with specified scheme has not installed
    case AppWithSchemeNotInstalled(scheme: String)
    // Failed to create NSURL for request
    case FailedToCreateRequestURL(components: NSURLComponents)
    // You specify a callback but no manager.callbackURLScheme defined
    case CallbackURLSchemeNotDefined
}

// MARK: - x-callback-url
let kXCUPrefix       = "x-"
let kXCUHost         = "x-callback-url"

// Parameters

//  The friendly name of the source app calling the action. If the action in the target app requires user interface elements, it may be necessary to identify to the user the app requesting the action.
let kXCUSource       = "x-source"
// If the action in the target method is intended to return a result to the source app, the x-callback parameter should be included and provide a URL to open to return to the source app. On completion of the action, the target app will open this URL, possibly with additional parameters tacked on to return a result to the source app. If x-success is not provided, it is assumed that the user will stay in the target app on successful completion of the action.
let kXCUSuccess      = "x-success"
// URL to open if the requested action generates an error in the target app. This URL will be open with at least the parameters “errorCode=code&errorMessage=message”. If x-error is not present, and a error occurs, it is assumed the target app will report the failure to the user and remain in the target app.
let kXCUError        = "x-error"
let kXCUErrorCode    = "error-Code"
let kXCUErrorMessage = "errorMessage"
// URL to open if the requested action is cancelled by the user. In the case where the target app offer the user the option to “cancel” the requested action, without a success or error result, this the the URL that should be opened to return the user to the source app.
let kXCUCancel       = "x-cancel"


// MARK: - framework strings

let kResponse  = "response"
let kResponseType = "responseType";
let kRequestID  = "requestID"
let protocolKeys = [kResponse, kResponseType, kRequestID]