//
//  ViewController.swift
//  FoodTracker
//
//  Created by Brian Vo on 2018-05-18.
//  Copyright © 2018 Brian Vo. All rights reserved.
//

import UIKit
import os.log

protocol AddMealProtocol {
    func addMeal(meal: Meal);
}

class MealViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var caloriesTextField: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    /*
     This value is either passed by `MealTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var meal: Meal?
    var cloudTracker: CloudTrackerAPIRequest?
    var imgurRequest: ImgurAPIRequest?
    var delegate: AddMealProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cloudTracker = CloudTrackerAPIRequest()
        imgurRequest = ImgurAPIRequest()
        nameTextField.delegate = self
        // Set up views if editing an existing Meal.
        if let meal = meal {
            navigationItem.title = meal.name
            nameTextField.text   = meal.name
            if let photoURL = meal.photoURL {
                imgurRequest?.getImage(url: photoURL, completion: { (data, error) -> (Void) in
                    self.photoImageView.image = UIImage(data: data!)
                })
            }
            ratingControl.rating = meal.rating
        }
        updateSaveButtonState()
    }
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        // Hide the keyboard.
        nameTextField.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        photoImageView.image = selectedImage
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddMealMode = presentingViewController is UINavigationController
        
        if isPresentingInAddMealMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        let name = nameTextField.text ?? ""
        let photo = photoImageView.image
        let rating = ratingControl.rating
        let calories = Int(caloriesTextField.text ?? "0")!
        let mealDescription = descriptionTextField.text ?? ""
        
        
        // POST request to save meal
        let postData: [String: Any] = [
            "title": name,
            "description": mealDescription,
            "calories": calories
        ]
        
        let token = UserDefaults.standard.value(forKey: "login_token") as! String
        
        let requestBody = ["token": token,
                           "Content-Type": "application/json"]
        
        // POST TO CREATE MEAL
        cloudTracker?.post(data: postData as [String : AnyObject], endpoint: "users/me/meals", requestBody: requestBody, completion: { (json, error) -> (Void) in
            if let json = json!["meal"] as? [String: Any] {
                let id = json["id"] as! Int
                let userId = json["user_id"] as! Int
                
                // SECOND POST FOR RATING
                self.cloudTracker?.post(data: ["rating": rating as AnyObject], endpoint: "users/me/meals/\(id)/rate", requestBody: requestBody, completion: { (json, error) -> (Void) in
                    
                    self.meal = Meal(name: name, photo: photo, rating: rating, calories: calories, mealDescription: mealDescription, id: id, userId: userId)
                    self.delegate?.addMeal(meal: self.meal!)
                    
                    // POST to Imgure API
                    let imgData = UIImageJPEGRepresentation(photo!, 1.0)
                    self.imgurRequest?.post(data: imgData, completion: { (json, error) -> (Void) in
                        if let json = json {
                            //print(json)
                            let imgurData = json["data"] as! [String: Any]
                            let link = imgurData["link"] as! String
                            
                            // POST to CloudTracker for PHOTO
                            self.cloudTracker?.post(data: ["photo": link as AnyObject], endpoint: "users/me/meals/\(id)/photo", requestBody: requestBody, completion: { (json, error) -> (Void) in })
                        }
                    })
                
                })
            }
        })
    }


}

