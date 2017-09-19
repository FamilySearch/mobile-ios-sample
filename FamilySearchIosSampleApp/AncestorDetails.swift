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
    self.ancestorBirthLabelTitle.isHidden = true
    self.ancestorBirthLabelValue.isHidden = true
    self.ancestorDeathLabelTitle.isHidden = true
    self.ancestorDeathLabelValue.isHidden = true
    
    // get the access token from UserDefaults
    let preferences = UserDefaults.standard
    let accessToken = preferences.string(forKey: Utilities.KEY_ACCESS_TOKEN)
    
    Utilities.getImageFromUrl(person!.personLinkHref!, accessToken: accessToken!) { (data, response, error)  in
      DispatchQueue.main.async { [weak self] () -> Void in
        self?.ancestorImageView.image = UIImage(data: data!)
        self?.ancestorImageIndicator.hidesWhenStopped = true
        self?.ancestorImageIndicator.stopAnimating()
      }
    }
    
    // set labels
    self.ancestorNameLabel.text = person?.displayName
    
    // download data from Person.personLinkHref
    getAncestorDetailsData(person?.personLinkHref,
                           accessToken: accessToken!,
                           completionAncestorDetails: { [weak self] (personDetails, errorResponse) -> Void in
                            if (errorResponse == nil)
                            {
                              DispatchQueue.main.async(execute: {
                                self?.ancestorImageIndicator.hidesWhenStopped = true
                                self?.ancestorDataIndicator.stopAnimating()
                                self?.ancestorDataIndicator.isHidden = true
                                
                                // birth data
                                self?.ancestorBirthLabelTitle.text = NSLocalizedString("ancestorDetailsBirth", comment: "Birth:")
                                self?.ancestorBirthLabelTitle.isHidden = false
                                self?.ancestorBirthLabelValue.text = personDetails?.personBirthDate
                                self?.ancestorBirthLabelValue.isHidden = false
                                
                                // death data
                                if (personDetails?.personDeathDate != nil)
                                {
                                  self?.ancestorDeathLabelTitle.text = NSLocalizedString("ancestorDetailsDeath", comment: "Death:")
                                  self?.ancestorDeathLabelTitle.isHidden = false
                                  self?.ancestorDeathLabelValue.text = personDetails?.personDeathDate
                                  self?.ancestorDeathLabelValue.isHidden = false
                                }
                              })
                            }
    })
  }
  
  func getAncestorDetailsData(_ personUrlString:String?,
                              accessToken:String,
                              completionAncestorDetails:@escaping (_ responseDetails: PersonDetails?, _ reponseError: Error?) -> ())
  {
    
    guard let personUrlString = personUrlString, let ancestorDetailsUrl = URL(string: personUrlString) else {
      return
    }
    
    let configuration = URLSessionConfiguration.default
    let headers: [AnyHashable: Any] = ["Accept":"application/json", "Authorization":"Bearer " + accessToken]
    configuration.httpAdditionalHeaders = headers
    let session = URLSession(configuration: configuration)
    let ancestorDetailDataTask = session.dataTask(with: ancestorDetailsUrl, completionHandler: { (ancestorData, ancestorResponse, ancestorError) in
      if (ancestorError == nil)
      {
        do
        {
          guard let ancestryDataJson = try JSONSerialization.jsonObject(with: ancestorData!, options: .allowFragments) as? [String : Any],
            let persons = ancestryDataJson["persons"] as? [[String:AnyObject]],
            let person = persons.first,
            let display = person["display"] as? [String: Any],
            let birthDate = display["birthDate"] as? String,
            let deathDate = display["deathDate"] as? String else {
              return
          }
          print("ancestryDataJson = \(ancestryDataJson)")
          
          let personDetails = PersonDetails()
          personDetails.personBirthDate = birthDate
          personDetails.personDeathDate = deathDate
          
          completionAncestorDetails(personDetails, nil)
        }
        catch
        {
          completionAncestorDetails(nil, ancestorError)
        }
      }
    })
    
    ancestorDetailDataTask.resume()
  }
}
