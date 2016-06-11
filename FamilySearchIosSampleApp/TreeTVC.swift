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
    
    var personArray = NSArray()
    
    var accessToken : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the access token from NSUserDefaults
        let preferences = NSUserDefaults.standardUserDefaults()
        accessToken = preferences.stringForKey(Utilities.KEY_ACCESS_TOKEN)
        
        // get url for family tree from Collections
        Utilities.getUrlsFromCollections({ (collectionsResponse, error) -> Void in
            if (error == nil)
            {
                // download the Ancestry query url
                self.getAncestryQueryUrlAsString(collectionsResponse.familyTreeUrlString!,
                    completionQuery: {(responseTemplate, errorQuery) -> Void in
                        if (errorQuery == nil)
                        {
                            //print("template url = \(responseTemplate!)")
                            
                            // getAncestryTree
                            self.getAncestryTree(responseTemplate!,
                                userPersonId: self.user.personId!,
                                accessToken: self.accessToken!,
                                completionTree:{(responsePersons, errorTree) -> Void in
                                    if (errorTree == nil)
                                    {
                                        // set the received array, update table
                                        self.personArray = responsePersons! as NSArray as! [Person]
                                        dispatch_async(dispatch_get_main_queue(),{
                                            self.tableView.reloadData()
                                        })
                                    }
                                })
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
                    let entireTemplate = ancestryQuery!["template"] as! String
                    
                    // need to split the template URL, and get the left side of the { symbol
                    let templateSplit = entireTemplate.componentsSeparatedByString("{")
                    let template = templateSplit[0]
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
    func getAncestryTree(ancestryRootUrlString:String,
                         userPersonId:String, accessToken:String,
                         completionTree:(responsePersons:NSMutableArray?, errorTree:NSError?) ->())
    {
        var ancestryUrlString = ancestryRootUrlString + "?" + "person=" + userPersonId
        ancestryUrlString = ancestryUrlString + "&" + "generations=" + "4"
        
        let ancestryUrl = NSURL(string: ancestryUrlString);
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration();
        let headers: [NSObject : AnyObject] = ["Accept":"application/json", "Authorization":"Bearer " + accessToken];
        configuration.HTTPAdditionalHeaders = headers;
        let session = NSURLSession(configuration: configuration)
        
        let ancestryTreeTask = session.dataTaskWithURL(ancestryUrl!) { (ancestryData, ancestryResponse, ancestryError) in
            if (ancestryError == nil)
            {
                do
                {
                    let ancestryDataJson = try NSJSONSerialization.JSONObjectWithData(ancestryData!, options: .AllowFragments);
                    //print("ancestryDataJson = \(ancestryDataJson)")
                    
                    let persons = ancestryDataJson["persons"] as? [[String : AnyObject]]
                    let arrayOfPersons = NSMutableArray()
                    
                    for eachPerson in persons!
                    {
                        let person = Person()
                        //print("eachPerson = \(eachPerson)")
                        
                        // get the display.name string
                        let display = eachPerson["display"] as! NSDictionary
                        let displayName = display["name"] as! String
                        let lifespan = display["lifespan"] as! String
                        
                        // get the links.person.href string
                        let links = eachPerson["links"] as! NSDictionary
                        let personLink = links["person"] as! NSDictionary
                        let personLinkHref = personLink["href"] as! String
                        
                        person.displayName = displayName
                        person.lifespan = lifespan
                        person.personLinkHref = personLinkHref
                        arrayOfPersons.addObject(person)
                    }
                    
                    completionTree(responsePersons: arrayOfPersons, errorTree: nil)
                }
                catch
                {
                    print("Error getting ancestry tree data. Error = \(ancestryError)")
                    completionTree(responsePersons: nil, errorTree: ancestryError)
                }
            }
            else
            {
                completionTree(responsePersons: nil, errorTree: ancestryError)
            }
        }
        
        ancestryTreeTask.resume()
    }
    
    // MARK: - Table View Controller methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.personArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : PersonCell = self.tableView.dequeueReusableCellWithIdentifier("PersonCell")! as! PersonCell
        
        let person = personArray.objectAtIndex(indexPath.row) as! Person
        cell.ancestorName.text = person.displayName
        cell.ancestorLifespan.text = person.lifespan
        
        //print("personLinkHref \(person.personLinkHref)")
        
        Utilities.getImageFromUrl(person.personLinkHref!, accessToken: accessToken) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                cell.ancestorPicture.image = UIImage(data: data!)
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let person = personArray.objectAtIndex(indexPath.row) as! Person
        
        self.performSegueWithIdentifier("segueToAncestorDetails", sender: person)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueToAncestorDetails")
        {            
            let detailsVC = (segue.destinationViewController as? AncestorDetails)!
            detailsVC.person = sender as? Person
        }
    }
}















































