//
//  SignUpViewController.swift
//  FoodTracker
//
//  Created by Brian Vo on 2018-05-21.
//  Copyright © 2018 Brian Vo. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var cloudTracker: CloudTrackerAPIRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cloudTracker = CloudTrackerAPIRequest()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        let hasRegistered = defaults.bool(forKey: "token_registered")
        
        if hasRegistered {
            performSegue(withIdentifier: "login", sender: nil)
        }
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        let postData = [
            "username": usernameTextField.text ?? "",
            "password": passwordTextField.text ?? ""
        ]
        
        cloudTracker?.post(data: postData as [String : AnyObject], endpoint: "signup", completion: { (json, error) -> (Void) in
            if let json = json {
                let token = json["token"] as! String
                
                UserDefaults.standard.set(token, forKey: "token")
                UserDefaults.standard.set(true, forKey: "token_registered")
            }
        })
    }
}
