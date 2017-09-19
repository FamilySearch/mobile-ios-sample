//
//  LoginVC.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/3/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {
  
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var loginButtonOutlet: UIButton!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var dataUsageLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    unlockScreen()
    
    usernameTextField.placeholder = NSLocalizedString("usernamePlaceholderText", comment: "username, in email form")
    passwordTextField.placeholder = NSLocalizedString("passwordPlaceholderText", comment: "password")
    loginButtonOutlet.setTitle(NSLocalizedString("loginText", comment: "text for login button"), for: UIControlState.normal)
    dataUsageLabel.text = NSLocalizedString("loginDataUsage", comment: "description of data usage")
  }
  
  @IBAction func loginAction(_ sender: AnyObject)
  {
    lockScreen()
    
    guard let
      username = usernameTextField.text,
      let password = passwordTextField.text, !username.isEmpty && !password.isEmpty
      else {
        self.showAlert("Error", description: "User name or password missing")
        unlockScreen()
        return
    }
    
    // get initial GET call to collections
    Utilities.getUrlsFromCollections({ [weak self] (collectionsResponse, error) -> Void in
      
      guard error == nil else {
        print("Error getting collections data from server. Error = \(error.debugDescription)")
        self?.activityIndicator.stopAnimating()
        return
      }
      
      // get the login token
      self?.getToken(collectionsResponse.tokenUrlString!,
                     username: username,
                     password: password,
                     client_id: AppKeys.API_KEY,
                     completionToken: {(responseToken, errorToken) -> Void in
                      guard errorToken == nil else {
                        DispatchQueue.main.async(execute: {
                          self!.showAlert("Error", description: errorToken!.localizedDescription)
                          self!.unlockScreen()
                        })
                        
                        return
                      }
                      
                      // get user data, with the newly acquired token
                      self?.getCurrentUserData(collectionsResponse.currentUserString!,
                                               accessToken: responseToken!,
                                               completionCurrentUser:{(responseUser, errorUser) -> Void in
                                                guard errorToken == nil else {
                                                  DispatchQueue.main.async(execute: {
                                                    self!.showAlert("Error", description: errorToken!.localizedDescription)
                                                    self!.unlockScreen()
                                                  })
                                                  return
                                                }
                                                // all login data needed has been downloaded
                                                // push to the next view controller, in the main thread
                                                DispatchQueue.main.async(execute: {
                                                  [weak self] in
                                                  self?.performSegue(withIdentifier: "segueToTabBar", sender: responseUser)
                                                })
                      })
      }
      )
    })
  }
  
  func getToken(_ tokenUrlAsString : String, username : String, password : String, client_id : String, completionToken:@escaping (_ responseToken:String?, _ errorToken:Error?) -> ()) {
    let grant_type = "password"
    
    let params = "?username=" + username +
      "&password=" + password +
      "&grant_type=" + grant_type +
      "&client_id=" + AppKeys.API_KEY
    
    let urlAsString = tokenUrlAsString + params
    
    // create the post request
    var request = URLRequest(url: URL(string: urlAsString)!)
    request.httpMethod = "POST"
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      guard error == nil else {
        print("Error downloading token. Error: \(error.debugDescription)")
        completionToken(nil, error)
        return
      }
      do
      {
        guard let jsonToken = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] else {
          return
        }
        if let error = jsonToken["error"] as? String,
          let description = jsonToken["error_description"] as? String {
          print("\(error) \(description)")
          
          let userInfo = [NSLocalizedDescriptionKey : description]
          completionToken(nil, NSError(domain: "FamilySearch", code: 1, userInfo: userInfo))
        }
        else if let token = jsonToken["access_token"] as? String
        {
          // parse the json to get the access_token, and save this token in UserDefaults
          let preferences = UserDefaults.standard
          preferences.setValue(token, forKey: Utilities.KEY_ACCESS_TOKEN)
          preferences.synchronize()
          
          completionToken(token, nil)
        }
      }
      catch
      {
        print("Error parsing token JSON. Error: \(error)")
      }
      
    }
    
    task.resume()
  }
  
  // get the user data
  func getCurrentUserData(_ currentUserUrlString : String, accessToken : String, completionCurrentUser:@escaping (_ responseUser:User?, _ errorUser:Error?) -> ())
  {
    let currentUserUrl = URL(string: currentUserUrlString)
    
    let configuration = URLSessionConfiguration.default
    let headers: [AnyHashable: Any] = ["Accept":"application/json", "Authorization":"Bearer " + accessToken]
    configuration.httpAdditionalHeaders = headers
    let session = URLSession(configuration: configuration)
    
    let currentUserTask = session.dataTask(with: currentUserUrl!, completionHandler: { (data, currentUserResponse, errorUserData) in
      // parse the currentUser data
      do
      {
        guard let data = data,
          let currentUserJson = try JSONSerialization.jsonObject(with: data,
                                                                 options: .allowFragments) as? [String : Any],
          let usersJsonObject = currentUserJson["users"] as? [[String : AnyObject]],
          let userJsonObject = usersJsonObject.first else {
            print("The user JSON does not contain any data")
            completionCurrentUser(nil, nil)
            return
        }
        
        let user = User()
        user.id = userJsonObject["id"] as? String
        user.contactName = userJsonObject["contactName"] as? String
        user.helperAccessPin = userJsonObject["helperAccessPin"] as? String
        user.givenName = userJsonObject["givenName"] as? String
        user.familyName = userJsonObject["familyName"] as? String
        user.email = userJsonObject["email"] as? String
        user.country = userJsonObject["country"] as? String
        user.gender = userJsonObject["gender"] as? String
        user.birthDate = userJsonObject["birthDate"] as? String
        user.phoneNumber = userJsonObject["phoneNumber"] as? String
        user.mailingAddress = userJsonObject["mailingAddress"] as? String
        user.preferredLanguage = userJsonObject["preferredLanguage"] as? String
        user.displayName = userJsonObject["displayName"] as? String
        user.personId = userJsonObject["personId"] as? String
        user.treeUserId = userJsonObject["treeUserId"] as? String
        
        // The Memories activity will need the URL that comes from user.links.artifact.href
        // in order to get the memories data
        let links = userJsonObject["links"] as? [String: Any]
        let artifacts = links!["artifacts"] as? [String: Any]
        user.artifactsHref = artifacts!["href"] as? String
        
        completionCurrentUser(user, nil)
      }
      catch
      {
        completionCurrentUser(nil, errorUserData)
      }
    })
    currentUserTask.resume()
  }
  
  // MARK: - Segue methods
  override func prepare(for segue: UIStoryboardSegue, sender: Any?)
  {
    if (segue.identifier == "segueToTabBar")
    {
      let tabBarController : UITabBarController = (segue.destination as? UITabBarController)!
      tabBarController.tabBar.items![0].title = NSLocalizedString("tabAncestorsName", comment: "name for list tab")
      tabBarController.tabBar.items![1].title = NSLocalizedString("tabMemoriesName", comment: "name for memories tab")
      
      guard let treeTVC = tabBarController.viewControllers?[0] as? TreeTVC else {
        fatalError("The first viewController in the tabBarController should be an instance of TreeTVC")
      }
      // need to pass a User object to the tree table view controller
      treeTVC.user = sender as? User
      
      guard let memoriesVC = tabBarController.viewControllers?[1] as? MemoriesVC else {
        fatalError("The second viewController in the tabBarController should be an instance of MemoriesVC")
      }
      memoriesVC.user = sender as? User
      
      self.activityIndicator.stopAnimating()
    }
  }
  
  // MARK: - Private methods
  fileprivate func lockScreen() {
    usernameTextField.isEnabled = false
    passwordTextField.isEnabled = false
    activityIndicator.startAnimating()
  }
  
  fileprivate func unlockScreen() {
    usernameTextField.isEnabled = true
    passwordTextField.isEnabled = true
    activityIndicator.stopAnimating()
  }
}
