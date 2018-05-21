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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        let hasRegistered = defaults.bool(forKey: "token_registered")
        
        if hasRegistered {
            performSegue(withIdentifier: "mealTableView", sender: nil)
        }
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        let postData = [
            "username": usernameTextField.text ?? "",
            "password": passwordTextField.text ?? ""
        ]
        
        guard let postJSON = try? JSONSerialization.data(withJSONObject: postData, options: []) else {
            print("could not serialize json")
            return
        }
        
        let url = URL(string: "https://cloud-tracker.herokuapp.com/signup")!
        let request = NSMutableURLRequest(url: url)
        request.httpBody = postJSON
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            
            guard let data = data else {
                print("no data returned from server \(String(describing: error?.localizedDescription))")
                return
            }
            
            var json: [String: Any]?
            do {
                json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("json fail")
            }
            
            guard let response = response as? HTTPURLResponse else {
                print("no response returned from server \(String(describing: error))")
                return
            }
            
            print(json)
            print(response.statusCode)
            
            guard response.statusCode == 200 else {
                // handle error
                print("an error occurred)")
                return
            }
            
            if let json = json {
                let token = json["token"] as! String
                
                UserDefaults.standard.set(token, forKey: "token")
                UserDefaults.standard.set(true, forKey: "token_registered")
            }
    
        }
        // do something with the json object
        task.resume()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
