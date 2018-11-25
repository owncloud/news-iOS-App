//
//  PrefsViewController.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/23/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import KeychainAccess

class PrefsViewController: NSViewController {

    /*
    @property (strong) IBOutlet NSTextField *usernameTextField;
    @property (strong) IBOutlet NSSecureTextField *passwordTextField;
    @property (strong) IBOutlet NSTextField *statusLabel;
    @property (strong) IBOutlet NSTextField *serverTextField;
    @property (strong) IBOutlet NSProgressIndicator *connectionActivityIndicator;
    @property (strong) IBOutlet NSTabView *tabView;
    
    - (IBAction)doConnect:(id)sender;

    */
    
    @IBOutlet var serverTextField: NSTextField!
    @IBOutlet var usernameTextField: NSTextField!
    @IBOutlet var passwordTextField: NSSecureTextField!
    @IBOutlet var connectionActivityIndicator: NSProgressIndicator!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var tabView: NSTabView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func onConnect(_ sender: Any) {
    }
}
