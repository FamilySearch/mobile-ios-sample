//
//  TreeVC.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/6/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import UIKit

class TreeTVC: UITableViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var user : User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the access token from NSUserDefaults
        let preferences = NSUserDefaults.standardUserDefaults()
        let accessToken = preferences.stringForKey(Utilities.KEY_ACCESS_TOKEN)
        
        // get url for family tree from Collections
        Utilities.getUrlsFromCollections({ (collectionsResponse, error) -> Void in
            if (error == nil)
            {
                // download the Ancestry query url
                self.getAncestryQueryUrlAsString(collectionsResponse.familyTreeUrlString!,
                    completionQuery: {(responseTemplate, errorQuery) -> Void in
                        if (errorQuery == nil)
                        {
                            print("template url = \(responseTemplate!)")
                            
                            // getAncestryTree
                            self.getAncestryTree(responseTemplate!, userPersonId: self.user.personId!, accessToken: accessToken!)
                        }
                })
            }
        })
    }
    
    func getAncestryQueryUrlAsString(familyTreeUrlAsString : String, completionQuery:(responseTemplate:String?, errorQuery:NSError?) -> ())
    {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let headers: [NSObject : AnyObject] = ["Accept":"application/json"];
        configuration.HTTPAdditionalHeaders = headers;
        let session = NSURLSession(configuration: configuration)
        
        let familyTreeTask = session.dataTaskWithURL(NSURL(string:familyTreeUrlAsString)! ) { (familyTreeData, response, familyTreeError) in
            do
            {
                let familyTreeJson = try NSJSONSerialization.JSONObjectWithData(familyTreeData!, options: .AllowFragments);
                //print("familyTreeJson = \(familyTreeJson)")
                
                // from here, we only care about the value of collections.links.ancestry-query.template, where collections is a json array
                if let collectionsJsonObject = familyTreeJson["collections"] as? [[String : AnyObject]]
                {
                    let collection = collectionsJsonObject.first!
                    let links = collection["links"] as? NSDictionary
                    let ancestryQuery = links!["ancestry-query"] as? NSDictionary
                    let template = ancestryQuery!["template"] as! String
                    completionQuery(responseTemplate:template, errorQuery:nil)
                }

            }
            catch
            {
                print("Error parsing the ancestry-query")
                completionQuery(responseTemplate:nil, errorQuery:familyTreeError)
            }
        }
        familyTreeTask.resume()
    }
    
    // getAncestryTree
    func getAncestryTree(ancestryUrlString:String, userPersonId:String, accessToken:String) ->()
    {
        // TODO
    }
}