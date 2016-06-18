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
        
        // hide data labels until the data gets downloaded
        self.ancestorBirthLabelTitle.hidden = true
        self.ancestorBirthLabelValue.hidden = true
        self.ancestorDeathLabelTitle.hidden = true
        self.ancestorDeathLabelValue.hidden = true
        
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
        
        // download data from Person.personLinkHref
        getAncestorDetailsData((person?.personLinkHref)!,
                               accessToken: accessToken!,
                               completionAncestorDetails: {(personDetails, errorResponse) -> Void in
                                    if (errorResponse == nil)
                                    {
                                        dispatch_async(dispatch_get_main_queue(),{
                                            self.ancestorImageIndicator.hidesWhenStopped = true
                                            self.ancestorDataIndicator.stopAnimating()
                                            self.ancestorDataIndicator.hidden = true
                                            
                                            // birth data
                                            self.ancestorBirthLabelTitle.text = NSLocalizedString("ancestorDetailsBirth", comment: "Birth:")
                                            self.ancestorBirthLabelTitle.hidden = false
                                            self.ancestorBirthLabelValue.text = personDetails?.personBirthDate
                                            self.ancestorBirthLabelValue.hidden = false
                                            
                                            // death data
                                            if (personDetails?.personDeathDate != nil)
                                            {
                                                self.ancestorDeathLabelTitle.text = NSLocalizedString("ancestorDetailsDeath", comment: "Death:")
                                                self.ancestorDeathLabelTitle.hidden = false
                                                self.ancestorDeathLabelValue.text = personDetails?.personDeathDate
                                                self.ancestorDeathLabelValue.hidden = false
                                            }
                                        })
                                    }
                                })
    }
    
    func getAncestorDetailsData(personUrlString:String,
                                accessToken:String,
                                completionAncestorDetails:(responseDetails: PersonDetails?, reponseError:NSError?) -> ())
    {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let headers: [NSObject : AnyObject] = ["Accept":"application/json", "Authorization":"Bearer " + accessToken];
        configuration.HTTPAdditionalHeaders = headers;
        let session = NSURLSession(configuration: configuration)
        let ancestorDetailDataTask = session.dataTaskWithURL(NSURL(string: personUrlString)!) { (ancestorData, ancestorResponse, ancestorError) in
            if (ancestorError == nil)
            {
                do
                {
                    let ancestryDataJson = try NSJSONSerialization.JSONObjectWithData(ancestorData!, options: .AllowFragments);
                    // print("ancestryDataJson = \(ancestryDataJson)")

                    let persons = ancestryDataJson["persons"] as! [[String:AnyObject]]
                    let person = persons.first
                    
                    let display = person!["display"] as! NSDictionary
                    
                    let birthDate = display["birthDate"] as! String
                    let deathDate = display["deathDate"] as! String
                    
                    let personDetails = PersonDetails()
                    personDetails.personBirthDate = birthDate
                    personDetails.personDeathDate = deathDate
                    
                    completionAncestorDetails(responseDetails: personDetails, reponseError: nil)
                }
                catch
                {
                    completionAncestorDetails(responseDetails: nil, reponseError: ancestorError)
                }
            }
        }
        
        ancestorDetailDataTask.resume()
    }
}











































