//
//  SwiftMessagesHelper.swift
//  iOCNews
//
//  Created by Peter Hedlund on 11/12/20.
//  Copyright © 2020 Peter Hedlund. All rights reserved.
//

import Foundation
import UIKit
import SwiftMessages

public typealias ButtonCallback = () -> Void

open class Messenger : NSObject {
    
    @objc
    public enum MessageTheme: Int {
        case info
        case success
        case warning
        case error
    }
    
    @objc
    open class func showMessage(title: String, body: String, theme: MessageTheme) {
        var config = SwiftMessages.defaultConfig
        config.interactiveHide = true
        config.duration = .forever
        config.preferredStatusBarStyle = .default
        SwiftMessages.show(config: config, viewProvider: {
            let view = MessageView.viewFromNib(layout: .cardView)
            var smTheme: Theme = .error
            switch theme {
            case .info:
                smTheme = .info
            case .success:
                smTheme = .success
            case .warning:
                smTheme = .warning
            case .error:
                smTheme = .error
            }
            view.configureTheme(smTheme, iconStyle: .default)
            view.configureDropShadow()
            view.button?.isHidden = true
            view.configureContent(title: title,
                                  body: body,
                                  iconImage: Icon.error.image
            )
            return view
        })
    }

    @objc
    open class func showSyncMessage(viewController: UIViewController) {
        var config = SwiftMessages.defaultConfig
        config.duration = .forever
        config.preferredStatusBarStyle = .default
        config.presentationContext = .viewController(viewController)
        SwiftMessages.show(config: config, viewProvider: {
            let view = MessageView.viewFromNib(layout: .cardView)
            view.configureTheme(.success, iconStyle: .default)
            view.configureDropShadow()
            view.configureContent(title: NSLocalizedString("Success", comment: "A message title"),
                                  body: NSLocalizedString("You are now connected to Notes on your server", comment: "A message"),
                                  iconImage: Icon.success.image,
                                  iconText: nil,
                                  buttonImage: nil,
                                  buttonTitle: NSLocalizedString("Close & Sync", comment: "Title of a button allowing the user to close the login screen and sync with the server"),
                                  buttonTapHandler: { _ in
                                    SwiftMessages.hide()
                                    viewController.dismiss(animated: true, completion: nil)
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SyncNews"), object: nil)
            })
            return view
        })
    }
    
    @objc
    open class func showAddMessage(message: String, viewController: UIViewController, callback: @escaping ButtonCallback) {
        var config = SwiftMessages.defaultConfig
        config.duration = .forever
        config.preferredStatusBarStyle = .default
        config.presentationContext = .viewController(viewController)
        SwiftMessages.show(config: config, viewProvider: {
            let view = MessageView.viewFromNib(layout: .cardView)
            view.configureTheme(.info, iconStyle: .default)
            view.configureDropShadow()
            view.configureContent(title: NSLocalizedString("Add Feed", comment: "A message title for adding a feed"),
                                  body: message,
                                  iconImage: Icon.info.image,
                                  iconText: nil,
                                  buttonImage: nil,
                                  buttonTitle: NSLocalizedString("Add", comment: "Title of a button allowing the user to add a feed"),
                                  buttonTapHandler: { _ in
                                    SwiftMessages.hide()
                                    callback()
            })
            return view
        })

    }

}
