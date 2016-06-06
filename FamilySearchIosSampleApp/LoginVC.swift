//
//  LoginVC.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/3/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get initial GET call to collections
        Utilities.getUrlsFromCollections({ (response, error) -> Void in
            if (error == nil)
            {
                print("link token = \(response.tokenUrlString!)")
                print("link currentUser = \(response.currentUserString)")
            }
            else
            {
                print("Error getting collectinos data from server. Error = \(error?.description)")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

