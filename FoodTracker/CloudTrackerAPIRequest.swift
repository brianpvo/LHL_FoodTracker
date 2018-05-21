//
//  CloudTrackerAPIRequest.swift
//  FoodTracker
//
//  Created by Brian Vo on 2018-05-21.
//  Copyright © 2018 Brian Vo. All rights reserved.
//

import UIKit

class CloudTrackerAPIRequest: NSObject {
    
    func post(data: [String: AnyObject], endpoint: String, requestBody: [String: String]?,  completion: @escaping ([String: Any]?, Error?)->(Void)) {
        guard let postJSON = try? JSONSerialization.data(withJSONObject: data, options: []) else {
            print("could not serialize json")
            return
        }
        
        let url = URL(string: "https://cloud-tracker.herokuapp.com/\(endpoint)")!
        let request = NSMutableURLRequest(url: url)
        request.httpBody = postJSON
        request.httpMethod = "POST"
        
        if let requestBody = requestBody {
            if let tokenValue = requestBody["token"] {
                request.addValue(tokenValue, forHTTPHeaderField: "token")
            }
            if let contentValue = requestBody["Content-Type"] {
                request.addValue(contentValue, forHTTPHeaderField: "Content-Type")
            }
        }
        
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
            
            guard response.statusCode == 200 else {
                // handle error
                print("an error occurred)")
                return
            }
            
            DispatchQueue.main.async {
                completion(json, error)
            }
            
        }
        // do something with the json object
        task.resume()
    }
    
//    func saveMeal(<#parameters#>) -> <#return type#> {
//        <#function body#>
//    }

}
