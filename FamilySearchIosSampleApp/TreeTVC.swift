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
  @IBOutlet weak var navItemTitle: UINavigationItem!
  
  var user : User?
  
  var personArray = [Person]()
  
  var accessToken : String?
  
  let cache = NSCache<AnyObject, AnyObject>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    Utilities.displayWaitingView(self.view)
    
    // set cache limits to 20 images or 10mb
    cache.countLimit = 50
    cache.totalCostLimit = 30*1024*1024
    
    // get the access token from UserDefaults
    let preferences = UserDefaults.standard
    accessToken = preferences.string(forKey: Utilities.KEY_ACCESS_TOKEN)
    
    // get url for family tree from Collections
    Utilities.getUrlsFromCollections({ [weak self] (collectionsResponse, error) -> Void in
      if (error == nil)
      {
        // download the Ancestry query url
        self?.getAncestryQueryUrlAsString(collectionsResponse.familyTreeUrlString!,
                                          completionQuery: {(responseTemplate, errorQuery) -> Void in
                                            if (errorQuery == nil)
                                            {
                                              // getAncestryTree
                                              self?.getAncestryTree(responseTemplate!,
                                                                    userPersonId: (self?.user!.personId!)!,
                                                                    accessToken: (self?.accessToken!)!,
                                                                    completionTree:{(responsePersons, errorTree) -> Void in
                                                                      if (errorTree == nil)
                                                                      {
                                                                        // set the received array, update table
                                                                        guard let responsePersons = responsePersons else {
                                                                          return
                                                                        }
                                                                        self?.personArray = responsePersons
                                                                        DispatchQueue.main.async(execute: {
                                                                          
                                                                          // remove loading spinner view from tvc
                                                                          Utilities.removeWaitingView((self?.view)!)
                                                                          
                                                                          // update table view
                                                                          self?.tableView.reloadData()
                                                                        })
                                                                      }
                                              })
                                            }
        })
      }
    })
  }
  
  func getAncestryQueryUrlAsString(_ familyTreeUrlAsString : String, completionQuery:@escaping (_ responseTemplate:String?, _ errorQuery:Error?) -> ())
  {
    let configuration = URLSessionConfiguration.default
    let headers: [AnyHashable: Any] = ["Accept":"application/json"]
    configuration.httpAdditionalHeaders = headers
    let session = URLSession(configuration: configuration)
    
    let familyTreeTask = session.dataTask(with: URL(string:familyTreeUrlAsString)!, completionHandler: { (familyTreeData, response, familyTreeError) in
      do
      {
        guard let familyTreeJson = try JSONSerialization.jsonObject(with: familyTreeData!, options: .allowFragments) as? [String : Any],
          let collectionsJsonObject = familyTreeJson["collections"] as? [[String : AnyObject]] else {
            return
        }
        // from here, we only care about the value of collections.links.ancestry-query.template, where collections is a json array
        let collection = collectionsJsonObject.first!
        let links = collection["links"] as? [String: Any]
        let ancestryQuery = links!["ancestry-query"] as? [String: Any]
        let entireTemplate = ancestryQuery!["template"] as! String
        
        // need to split the template URL, and get the left side of the { symbol
        let templateSplit = entireTemplate.components(separatedBy: "{")
        let template = templateSplit[0]
        completionQuery(template, nil)
      }
      catch
      {
        print("Error parsing the ancestry-query")
        completionQuery(nil, familyTreeError)
      }
    } )
    familyTreeTask.resume()
  }
  
  // getAncestryTree
  func getAncestryTree(_ ancestryRootUrlString:String,
                       userPersonId:String, accessToken:String,
                       completionTree:@escaping (_ responsePersons:[Person]?, _ errorTree:Error?) ->())
  {
    var ancestryUrlString = ancestryRootUrlString + "?" + "person=" + userPersonId
    ancestryUrlString = ancestryUrlString + "&" + "generations=" + "4"
    
    let ancestryUrl = URL(string: ancestryUrlString)
    
    let configuration = URLSessionConfiguration.default
    let headers: [AnyHashable: Any] = ["Accept":"application/json", "Authorization":"Bearer " + accessToken]
    configuration.httpAdditionalHeaders = headers
    let session = URLSession(configuration: configuration)
    
    let ancestryTreeTask = session.dataTask(with: ancestryUrl!, completionHandler: { (ancestryData, ancestryResponse, ancestryError) in
      if (ancestryError == nil)
      {
        do
        {
          guard let ancestryDataJson = try JSONSerialization.jsonObject(with: ancestryData!, options: .allowFragments) as? [String : Any] else {
            return
          }
          //print("ancestryDataJson = \(ancestryDataJson)")
          
          let persons = ancestryDataJson["persons"] as? [[String : AnyObject]]
          var people = [Person]()
          
          for eachPerson in persons!
          {
            let person = Person()
            //print("eachPerson = \(eachPerson)")
            
            // get the display.name string
            let display = eachPerson["display"] as! [String: Any]
            let displayName = display["name"] as! String
            let lifespan = display["lifespan"] as! String
            
            // get the links.person.href string
            let links = eachPerson["links"] as! [String: Any]
            let personLink = links["person"] as! [String: Any]
            let personLinkHref = personLink["href"] as! String
            
            person.displayName = displayName
            person.lifespan = lifespan
            person.personLinkHref = personLinkHref
            people.append(person)
          }
          
          completionTree(people, nil)
        }
        catch
        {
          print("Error getting ancestry tree data. Error = \(ancestryError.debugDescription)")
          completionTree(nil, ancestryError)
        }
      }
      else
      {
        completionTree(nil, ancestryError)
      }
    })
    
    ancestryTreeTask.resume()
  }
  
  // MARK: - Table View Controller methods
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.personArray.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell : PersonCell = self.tableView.dequeueReusableCell(withIdentifier: "PersonCell")! as! PersonCell
    
    let person = personArray[indexPath.row]
    cell.ancestorName.text = person.displayName
    cell.ancestorLifespan.text = person.lifespan
    
    // set default ancestorImage to display while scrolling
    cell.ancestorPicture.image = UIImage(named: "genderUnknownCircle2XL")
    
    if let imageLink = person.personLinkHref
    {
      // the code below is to create an image cache
      var ancestorImage = UIImage()
      if let cachedImage = cache.object(forKey: imageLink as AnyObject) as? UIImage
      {
        // image exists in cache, so use the cached image
        ancestorImage = cachedImage
        cell.ancestorPicture.image = ancestorImage
      }
      else
      {
        // no image found in cache, so need to create cached image from download service
        Utilities.getImageFromUrl(imageLink, accessToken: accessToken!) { (data, response, error)  in
          DispatchQueue.main.async { () -> Void in
            ancestorImage = UIImage(data: data!)!
            self.cache.setObject(ancestorImage, forKey: imageLink as AnyObject)
            cell.ancestorPicture.image = ancestorImage
          }
        }
      }
    }
    else
    {
      // TODO: handle case for when the image link is nil
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let person = personArray[indexPath.row]
    
    self.performSegue(withIdentifier: "segueToAncestorDetails", sender: person)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.identifier == "segueToAncestorDetails")
    {
      let detailsVC = (segue.destination as? AncestorDetails)!
      detailsVC.person = sender as? Person
    }
  }
}
