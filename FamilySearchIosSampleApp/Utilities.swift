//
//  Utilities.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/4/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import Foundation

class Utilities: NSObject {
    
    static func getUrlsFromCollections(completionHandler:(response:Links, error:NSError?) -> ())
    {
        let collectionUrlString = "https://familysearch.org/platform/collection"
        
        let linksObject = Links()
        
        let collectionUrl = NSURL(string: collectionUrlString);
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let headers: [NSObject : AnyObject] = ["Accept":"application/json"];
        configuration.HTTPAdditionalHeaders = headers;
        let session = NSURLSession(configuration: configuration);
        
        
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
                            if let endpointUrlObject = links["http://oauth.net/core/2.0/endpoint/authorize"] as? [String : AnyObject]
                            {
                                if let endpointUrlString = endpointUrlObject["href"] as? String
                                {
                                    linksObject.tokenUrlString = endpointUrlString
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
}
