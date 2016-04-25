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
        
        // create network request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                print(error)
                print("URL at time of error: \(url)")
                self.toggleUIState(enabled: true)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request.")
                return
            }
            
            /* GUARD: Did we get a successful HTTP response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("HTTP Response outside of 2xx returned.")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: AnyObject!
                    
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                displayError("Error occured parsing JSON: \(data)")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok) ? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String where stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject], photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as?[[String:AnyObject]] else {
                
                displayError("Cannot find keys: \(Constants.FlickrResponseKeys.Photos) and \(Constants.FlickrResponseKeys.Photo)")
                return
            }
            
            // select a random photo
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let randomPhotoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
            let photoTitle = randomPhotoDictionary[Constants.FlickrResponseKeys.Title] as? String
            
            /* GUARD: Does our photo have a key for 'url_m'? */
            guard let imageURLString = randomPhotoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                displayError("Cannot find key \(Constants.FlickrResponseKeys.MediumURL)")
                return
            }
            
            let randomPhotoURL = NSURL(string: imageURLString)
            
            /* GUARD: Does an image exist at the URL? */
            guard let randomPhotoData = NSData(contentsOfURL: randomPhotoURL!) else {
                displayError("Cannot convert URL into Data")
                return
            }
            
            // perform ui updates on main
            dispatch_async(dispatch_get_main_queue(), {
                self.photoImageDescription.text = photoTitle
                self.photoImageView.image = UIImage(data: randomPhotoData)
                self.toggleUIState(enabled: true)
            })
        }
        
        // Start the task
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

