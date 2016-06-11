//
//  AncestorDetails.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/10/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import Foundation
import UIKit

class AncestorDetails : UIViewController
{
    @IBOutlet weak var ancestorImageView: UIImageView!
    @IBOutlet weak var ancestorNameLabel: UILabel!
    @IBOutlet weak var ancestorBirthLabelTitle: UILabel!
    @IBOutlet weak var ancestorBirthLabelValue: UILabel!
    @IBOutlet weak var ancestorDeathLabelTitle: UILabel!
    @IBOutlet weak var ancestorDeathLabelValue: UILabel!
    @IBOutlet weak var ancestorImageIndicator: UIActivityIndicatorView!
    @IBOutlet weak var ancestorDataIndicator: UIActivityIndicatorView!
    
    var person : Person?
    
    override func viewDidLoad() {
        self.navigationItem.title = NSLocalizedString("ancestorDetailsTitle", comment: "Word Ancestor")
        
        // get the access token from NSUserDefaults
        let preferences = NSUserDefaults.standardUserDefaults()
        let accessToken = preferences.stringForKey(Utilities.KEY_ACCESS_TOKEN)
        
        Utilities.getImageFromUrl(person!.personLinkHref!, accessToken: accessToken!) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.ancestorImageView.image = UIImage(data: data!)
                self.ancestorImageIndicator.hidesWhenStopped = true
                self.ancestorImageIndicator.stopAnimating()
            }
        }
        
        // set labels
        self.ancestorNameLabel.text = person?.displayName
    }
}