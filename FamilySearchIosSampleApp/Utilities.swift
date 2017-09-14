//
//  Utilities.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/4/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import Foundation
import UIKit

class Utilities: NSObject {
  
  static let KEY_ACCESS_TOKEN = "access_token";
  
  static func getUrlsFromCollections(_ completionHandler:@escaping (_ response:Links, _ error:Error?) -> ())
  {
    let collectionUrlString = "https://familysearch.org/platform/collection"
    
    let linksObject = Links()
    
    let collectionUrl = URL(string: collectionUrlString);
    
    let configuration = URLSessionConfiguration.default;
    let headers: [AnyHashable: Any] = ["Accept":"application/json"];
    configuration.httpAdditionalHeaders = headers;
    let session = URLSession(configuration: configuration)
    
    let configurationUrlTask = session.dataTask(with: collectionUrl!, completionHandler: {(data, response, error) in
      
      // parse the list of possible configuration urls, go just get the
      do
      {
        guard let data = data,
          let jsonCollections = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : AnyObject],
          let collectionsJsonObject = jsonCollections["collections"] as? [[String : AnyObject]] else {
            return
        }
        
        for collection in collectionsJsonObject
        {
          if let links = collection["links"] as? [String : AnyObject]
          {
            // uncomment the line below to see the list of links available
            //print("links = \(links)");
            
            // get the url to get the token
            if let tokenUrlObject = links["http://oauth.net/core/2.0/endpoint/token"] as? [String : AnyObject]
            {
              if let tokenUrlString = tokenUrlObject["href"] as? String
              {
                linksObject.tokenUrlString = tokenUrlString
              }
            }
            
            // get the url to get the data for the current user
            if let currentUserUrlObject = links["current-user"] as? [String : AnyObject]
            {
              if let currentUserUrlString = currentUserUrlObject["href"] as? String
              {
                linksObject.currentUserString = currentUserUrlString
              }
            }
            
            // get the url to get the data for the family tree
            if let familyTreeUrlObject = links["family-tree"] as? [String : AnyObject]
            {
              if let familyTreeUrlString = familyTreeUrlObject["href"] as? String
              {
                linksObject.familyTreeUrlString = familyTreeUrlString
              }
            }
          }
        }
      }
      catch
      {
        print("Error parsing collections JSON. Error: \(error)");
      }
      
      completionHandler(linksObject, error)
    })
    
    configurationUrlTask.resume()
  }
  
  // helper function to download images
  static func getImageFromUrl(_ urlAsString:String, accessToken:String, completion: @escaping ((_ data: Data?, _ response: URLResponse?, _ error: Error? ) -> Void))
  {
    // this is the url of the default image
    // notice that this url is HTTP, which means that the app has to allow arbitraty loads for non-HTTPS calls.
    // This can be found under Target > Info > App Transport Security Settings
    let defaultImageUrl = "http://fsicons.org/wp-content/uploads/2014/10/gender-unknown-circle-2XL.png"
    
    var imageUrlString = urlAsString + "/portrait"
    imageUrlString = imageUrlString + "?access_token=" + accessToken;
    imageUrlString = imageUrlString + "&default=" + defaultImageUrl;
    URLSession.shared.dataTask(with: URL(string: imageUrlString)!, completionHandler: { (data, response, error) in
      completion(data, response, error)
    }) .resume()
  }
  
  // helper function to display an activity indicator
  static func displayWaitingView(_ view:UIView)
  {
    // creating a loading spinner on top of the table view controller, while data downloads
    let waitingView = WaitingView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
    let spinnerWhileWaiting = UIActivityIndicatorView(frame: CGRect(x: view.frame.width / 2, y: view.frame.height / 2, width: 0, height: 0))
    spinnerWhileWaiting.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
    spinnerWhileWaiting.color = UIColor.lightGray
    spinnerWhileWaiting.startAnimating()
    waitingView.addSubview(spinnerWhileWaiting)
    view.addSubview(waitingView)
  }
  
  // helper function to remove the activity indicator created by displayWaitingView
  static func removeWaitingView(_ view:UIView)
  {
    for eachView in view.subviews
    {
      if eachView.isKind(of: WaitingView.self)
      {
        eachView.removeFromSuperview()
      }
    }
  }
}
