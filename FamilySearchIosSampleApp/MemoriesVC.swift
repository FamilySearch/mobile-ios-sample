//
//  MemoriesVC.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/11/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import Foundation
import UIKit

class MemoriesVC : UICollectionViewController
{
    var user : User?
    
    let arrayOfImageThumbnailHrefs = NSMutableArray()
    
    var accessToken : String?
    
    override func viewDidLoad() {
        
        // display waiting activity indicator
        Utilities.displayWaitingView(self.view)
        
        // get the access token from NSUserDefaults
        let preferences = NSUserDefaults.standardUserDefaults()
        accessToken = preferences.stringForKey(Utilities.KEY_ACCESS_TOKEN)
        
        // get an array of the links of images
        getMemoriesLinksForUser(accessToken!,
                                 completionLinks: {(completionLinks, errorLinks) -> Void in
                                    if (errorLinks == nil)
                                    {
                                        // update collection view to display images
                                        dispatch_async(dispatch_get_main_queue(),
                                            {
                                                // remove waiting activity indicator
                                                Utilities.removeWaitingView(self.view)
                                                
                                                // update collectionView
                                                self.collectionView?.reloadData()
                                            })
                                    }
        })
    }
    
    func getMemoriesLinksForUser(accessToken:String,
                                  completionLinks:(responseLinks:NSMutableArray?, errorLinks:NSError?) -> ())
    {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let headers: [NSObject : AnyObject] = ["Accept":"application/json", "Authorization":"Bearer " + accessToken];
        configuration.HTTPAdditionalHeaders = headers;
        let session = NSURLSession(configuration: configuration)
        
        guard let memoriesHref = NSURL(string: user!.artifactsHref!) else {
            return
        }
        
        let memoriesTask = session.dataTaskWithURL(memoriesHref) { [weak self] (memoriesData, response, memoriesError) in
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
                        let linkImageThumbnail = links?["image-thumbnail"] as? NSDictionary
                        let linkImageThumbnailHref = linkImageThumbnail!["href"] as? String
                        self?.arrayOfImageThumbnailHrefs.addObject(linkImageThumbnailHref!)
                    }
                    else
                    {
                        continue
                    }
                }
                completionLinks(responseLinks: self?.arrayOfImageThumbnailHrefs, errorLinks: nil)
            }
            catch
            {
                completionLinks(responseLinks: nil, errorLinks: memoriesError)
            }
        }
        memoriesTask.resume()
    }
    
    // MARK: - UI Collection View Controller methods
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrayOfImageThumbnailHrefs.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MemoryCell", forIndexPath: indexPath) as! MemoryCell
        
        let linkHref = arrayOfImageThumbnailHrefs.objectAtIndex(indexPath.row) as? String
        Utilities.getImageFromUrl(linkHref!, accessToken: accessToken!) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let imageData = data else {
                    // no image data
                    return
                }
                cell.memoryImageView.image = UIImage(data: imageData)
            }
        }
        
        return cell
    }
}










































