//
//  MemoriesVC.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/11/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import Foundation
import UIKit

class MemoriesVC : UIViewController
{
    var user : User!
    
    override func viewDidLoad() {
        
        // get the access token from NSUserDefaults
        let preferences = NSUserDefaults.standardUserDefaults()
        let accessToken = preferences.stringForKey(Utilities.KEY_ACCESS_TOKEN)
        
        getMemoriesImagesForUser(accessToken!)
    }
    
    func getMemoriesImagesForUser(accessToken:String) -> ()
    {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let headers: [NSObject : AnyObject] = ["Accept":"application/json", "Authorization":"Bearer " + accessToken];
        configuration.HTTPAdditionalHeaders = headers;
        let session = NSURLSession(configuration: configuration)
        
        let memoriesTask = session.dataTaskWithURL(NSURL(string:user.artifactsHref!)! ) { (memoriesData, response, memoriesError) in
            do
            {
                let memoriesDataJson = try NSJSONSerialization.JSONObjectWithData(memoriesData!, options: .AllowFragments);
                
                let sourceDescriptions = memoriesDataJson["sourceDescriptions"] as? [NSDictionary]
                for sourceDescription in sourceDescriptions!
                {
                    // for this demo we're only downloading images, so we need to check if the sourceDescription contains an image
                    let mediaType = sourceDescription["mediaType"] as? String
                    if (mediaType == "image/jpeg")
                    {
                        let links = sourceDescription["links"] as? NSDictionary
                        let linkImageThumbnail = links!["image-thumbnail"] as? NSDictionary
                        let linkImageThumbnailHref = linkImageThumbnail!["href"] as? String
                        print("linkImageThumbnailHref = \(linkImageThumbnailHref!)")
                    }
                    else
                    {
                        continue
                    }
                }
            }
            catch
            {
                
            }
        }
        memoriesTask.resume()

    }
}