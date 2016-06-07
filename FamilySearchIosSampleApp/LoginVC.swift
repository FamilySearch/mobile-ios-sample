//
//  LoginVC.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/3/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {
    
    @IBOutlet weak var usernameTextFiew: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginAction(sender: AnyObject)
    {
        let username = usernameTextFiew.text!
        let password = passwordTextField.text!

        if ( !(username.isEmpty) && !(password.isEmpty))
        {
            // get initial GET call to collections
            Utilities.getUrlsFromCollections({ (response, error) -> Void in
                if (error == nil)
                {
                    self.getToken(response.tokenUrlString!, username: username, password: password, client_id: AppKeys.API_KEY)
                }
                else
                {
                    print("Error getting collections data from server. Error = \(error?.description)")
                }
            })
        }
        else
        {
            // TODO: display error for empty username or password
        }
    }
    
    func getToken(tokenUrlAsString : String, username : String, password : String, client_id : String) -> String {
        let grant_type = "password";
        
        let params = "?username=" + username +
            "&password=" + password +
            "&grant_type=" + grant_type +
            "&client_id=" + AppKeys.API_KEY;
        
        let urlAsString = tokenUrlAsString + params
        
        // create the post request
        let request = NSMutableURLRequest(URL: NSURL(string: urlAsString)!)
        request.HTTPMethod = "POST"
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request){ data, response, error in
            if (error != nil)
            {
                print("Error downloading token. Error: \(error)")
            }
            else
            {
                do
                {
                    let jsonToken = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments);
                    if let token = jsonToken["access_token"] as? String
                    {
                        // parse the json to get the access_token, and save this token in NSUserDefaults
                        let preferences = NSUserDefaults.standardUserDefaults()
                        preferences.setValue(token, forKey: Utilities.KEY_ACCESS_TOKEN)
                        preferences.synchronize()
                        
                        // push to the next view controller, in the main thread
                        dispatch_async(dispatch_get_main_queue(),{
                            self.performSegueWithIdentifier("segueToTabBar", sender: nil)
                            })
                    }
                }
                catch
                {
                    print("Error parsing token JSON. Error: \(error)");
                }
                
            }
        }
        
        task.resume()
        
        return "";
    }
}

