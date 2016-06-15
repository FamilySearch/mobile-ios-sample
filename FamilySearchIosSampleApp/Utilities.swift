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
    
    static func getUrlsFromCollections(completionHandler:(response:Links, error:NSError?) -> ())
    {
        let collectionUrlString = "https://familysearch.org/platform/collection"
        
        let linksObject = Links()
        
        let collectionUrl = NSURL(string: collectionUrlString);
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let headers: [NSObject : AnyObject] = ["Accept":"application/json"];
        configuration.HTTPAdditionalHeaders = headers;
        let session = NSURLSession(configuration: configuration)
        
        
        let configurationUrlTask = session.dataTaskWithURL(collectionUrl!) {(data, response, error) in
            
            // parse the list of possible configuration urls, go just get the
            do
            {
                let jsonCollections = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments);
                if let collectionsJsonObject = jsonCollections["collections"] as? [[String : AnyObject]]
                {
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
            }
            catch
            {
                print("Error parsing collections JSON. Error: \(error)");
            }
            
            completionHandler(response: linksObject, error: error)
        }
        
        configurationUrlTask.resume()
    }
    
    // helper function to download images
    static func getImageFromUrl(urlAsString:String, accessToken:String, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void))
    {
        // this is the url of the default image
        // notice that this url is HTTP, which means that the app has to allow arbitraty loads for non-HTTPS calls.
        // This can be found under Target > Info > App Transport Security Settings
        let defaultImageUrl = "http://fsicons.org/wp-content/uploads/2014/10/gender-unknown-circle-2XL.png"
        
        var imageUrlString = urlAsString + "/portrait"
        imageUrlString = imageUrlString + "?access_token=" + accessToken;
        imageUrlString = imageUrlString + "&default=" + defaultImageUrl;
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: imageUrlString)!) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    // helper function to display an activity indicator
    static func displayWaitingView(view:UIView)
    {
        // creating a loading spinner on top of the table view controller, while data downloads
        let waitingView = WaitingView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
        let spinnerWhileWaiting = UIActivityIndicatorView(frame: CGRectMake(view.frame.width / 2, view.frame.height / 2, 0, 0))
        spinnerWhileWaiting.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        spinnerWhileWaiting.color = UIColor.lightGrayColor()
        spinnerWhileWaiting.startAnimating()
        waitingView.addSubview(spinnerWhileWaiting)
        view.addSubview(waitingView)
    }
    
    // helper function to remove the activity indicator created by displayWaitingView
    static func removeWaitingView(view:UIView)
    {
        for eachView in view.subviews
        {
            if eachView.isKindOfClass(WaitingView)
            {
                eachView.removeFromSuperview()
            }
        }
    }
}
