//
//  LoginViewController.swift
//  FoodTracker
//
//  Created by Brian Vo on 2018-05-21.
//  Copyright © 2018 Brian Vo. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameFieldText: UITextField!
    @IBOutlet weak var passwordFieldText: UITextField!
    var cloudTracker: CloudTrackerAPIRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cloudTracker = CloudTrackerAPIRequest()
    }
    
    @IBAction func login(_ sender: UIButton) {
        let postData = [
            "username": usernameFieldText.text ?? "",
            "password": passwordFieldText.text ?? ""
        ]
        
        cloudTracker?.post(data: postData as [String : AnyObject], endpoint: "login", completion: { (json, error) -> (Void) in
            if let json = json, let tokenDefault = UserDefaults.standard.value(forKey: "token") as? String {
                let token = json["token"] as! String
                
                if token == tokenDefault {
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(token, forKey: "login_token")
                        self.performSegue(withIdentifier: "mealTableView", sender: nil)
                    }
                }
                
            }
        })
    }
    
    
}
