//
//  ExtensionsSwiftViewController.swift
//  FamilySearchIosSampleApp
//
//  Created by Douglas Campbell on 2016-07-29.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import UIKit

extension UIViewController {	
    func showAlert(title: String, description: String) {
        let alertController = UIAlertController(title: title,
                                                message: description,
                                                preferredStyle: .Alert)

        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
