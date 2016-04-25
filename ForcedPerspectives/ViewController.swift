//
//  ViewController.swift
//  ForcedPerspectives
//
//  Created by Patrick Montalto on 4/25/16.
//  Copyright © 2016 swift. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var photoImageDescription: UILabel!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var newImageButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func getNewImage(sender: AnyObject) {
        toggleUIState(enabled: false)
        getImageFromFlickr()
    }
    
    // MARK: Toggle UI when fetching new image
    
    private func toggleUIState(enabled enabled: Bool) {
        photoImageDescription.enabled = enabled
        newImageButton.enabled = enabled
        
        newImageButton.alpha = enabled ? 1.0 : 0.5
    }
    
    
    // MARK: Make network request
    private func getImageFromFlickr() {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.GalleryPhotosMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.GalleryID: Constants.FlickrParameterValues.GalleryID,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            
            if error == nil {
                
                if let data = data {
                    
                    let parsedResult: AnyObject!
                    
                    do {
                        parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    } catch {
                        print("Error occured parsing JSON: \(data)")
                        return
                    }
                    
                    if let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject],
                        let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] {
                        
                        let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                        let randomImageDictionary = photoArray[randomIndex]
                        
                        if let imageURLString = randomImageDictionary[Constants.FlickrResponseKeys.MediumURL] as? String,
                            let randomImageTitle = randomImageDictionary[Constants.FlickrResponseKeys.Title] as? String {
                            
                            let randomImageURL = NSURL(string: imageURLString)
                            
                            if let randomImageData = NSData(contentsOfURL: randomImageURL!) {
                                
                                // perform ui updates on main
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.photoImageDescription.text = randomImageTitle
                                    self.photoImageView.image = UIImage(data: randomImageData)
                                    self.toggleUIState(enabled: true)
                                })
                                
                            }
                            
                        }
                        
                    }
                }
                
            }
        }
        
        task.resume()
    }
    
    
    // MARK: Escape and concatenate parameters for URL
    
    private func escapedParameters(parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            
            return "?\(keyValuePairs.joinWithSeparator("&"))"
        }
    }
    
}

