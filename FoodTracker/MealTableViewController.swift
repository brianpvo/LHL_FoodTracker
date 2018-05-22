//
//  MealTableViewController.swift
//  FoodTracker
//
//  Created by Brian Vo on 2018-05-18.
//  Copyright © 2018 Brian Vo. All rights reserved.
//

import UIKit
import os.log

class MealTableViewController: UITableViewController, AddMealProtocol {

    //MARK: Properties
    
    var meals = [Meal]()
    var cloudTracker: CloudTrackerAPIRequest?
    var imgurRequest: ImgurAPIRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cloudTracker = CloudTrackerAPIRequest()
        imgurRequest = ImgurAPIRequest()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        if let savedMeals = loadMeals() {
            meals += savedMeals
        }
        //else {
            // Load the sample data.
         //   loadSampleMeals()
        //}
        let token = UserDefaults.standard.value(forKey: "login_token") as! String
        cloudTracker?.get(endpoint: "users/me/meals", token: token, completion: { (json, error) -> (Void) in
            if let mealArray = json {
                for meal in mealArray {
                    let mealObj = Meal(name: meal["title"] as! String,
                                       photo: nil,
                                       rating: meal["rating"] as! Int,
                                       calories: meal["calories"] as! Int,
                                       mealDescription: meal["description"] as! String,
                                       id: meal["id"] as! Int,
                                       userId: meal["user_id"] as! Int)
                    mealObj?.photoURL = meal["imagePath"] as? String
                    
                    self.meals.append(mealObj!)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return meals.count
    }

    /*
    private func loadSampleMeals() {
        let photo1 = UIImage(named: "meal1")
        let photo2 = UIImage(named: "meal2")
        let photo3 = UIImage(named: "meal3")
        guard let meal1 = Meal(name: "Caprese Salad", photo: photo1, rating: 4, calories: 50, mealDescription: "Greeny Salad") else {
            fatalError("Unable to instantiate meal1")
        }
        
        guard let meal2 = Meal(name: "Chicken and Potatoes", photo: photo2, rating: 5, calories: 200, mealDescription: "Protein and carbs") else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal3 = Meal(name: "Pasta with Meatballs", photo: photo3, rating: 3, calories: 300, mealDescription: "Protein and carbs") else {
            fatalError("Unable to instantiate meal3")
        }
        meals += [meal1, meal2, meal3]
    }
    */
    
    private func saveMeals() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(meals, toFile: Meal.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Meals successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save meals...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadMeals() -> [Meal]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Meal.ArchiveURL.path) as? [Meal]
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "mealCell", for: indexPath) as? MealTableViewCell else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }

        let meal = meals[indexPath.row]
        cell.nameLabel.text = meal.name
        cell.ratingControl.rating = meal.rating
        
        if let photoURL = meal.photoURL {
            imgurRequest?.getImage(url: photoURL, completion: { (data, error) -> (Void) in
                DispatchQueue.main.async {
                    meal.photo = UIImage(data: data!)
                    cell.photoImageView.image = meal.photo
                }
               
            })
        }

        return cell
    }
    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? MealViewController, let meal = sourceViewController.meal {
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                meals[selectedIndexPath.row] = meal
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // Add a new meal.
                let newIndexPath = IndexPath(row: meals.count, section: 0)
                
                meals.append(meal)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
            saveMeals()
        }
    }
 


    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
 

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            meals.remove(at: indexPath.row)
            saveMeals()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }


    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddItem":
            guard let mealDetailViewController = segue.destination as? MealViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            mealDetailViewController.delegate = self
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
            
        case "ShowDetail":
            guard let mealDetailViewController = segue.destination as? MealViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedMealCell = sender as? MealTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedMeal = meals[indexPath.row]
            mealDetailViewController.meal = selectedMeal
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    func addMeal(meal: Meal) {
        meals.append(meal)
        self.tableView.reloadData()
    }
    

}
