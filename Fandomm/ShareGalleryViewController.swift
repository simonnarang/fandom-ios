//
//  ShareGalleryViewController.swift
//  Fandomm
//
//  Created by Simon Narang on 12/13/15.
//  Copyright © 2015 Simon Narang. All rights reserved.
//

import UIKit

class ShareGalleryViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    //IBOUTLETS
    @IBOutlet weak var IMG: UIImageView!
    @IBOutlet weak var GalleryView: UIImageView!
    @IBOutlet weak var pixyView: UIImageView!
    
    //vars
    let imagePicker = UIImagePickerController()
    var userFandoms = [AnyObject]()
    let redisClient:RedisClient = RedisClient(host:"pub-redis-17342.us-east-1-4.3.ec2.garantiadata.com", port:17342, loggingBlock:{(redisClient:AnyObject, message:String, severity:RedisLogSeverity) in
        var debugString:String = message
        debugString = debugString.stringByReplacingOccurrencesOfString("\r", withString: "\\r")
        debugString = debugString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
        print("Log (\(severity.rawValue)): \(debugString)")
    })
    
    //after image is selected go to the general sharing screen
    @IBAction func GetIMG(sender: AnyObject) {
        performSegueWithIdentifier("segueSix", sender: nil)
    }
    
    //startup junk
    override func viewDidLoad() {
        super.viewDidLoad()
        //set up and present shareable image picker
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            pixyView.contentMode = .ScaleAspectFit
            pixyView.image = pickedImage
         dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueSix" {
            let destViewContOne: ShareToFandomNavigationViewController = segue.destinationViewController as! ShareToFandomNavigationViewController
            destViewContOne.shareImage = self.pixyView.image!
            destViewContOne.userFandoms = self.userFandoms
        }else {
            print("there is an undocumented segue form the preferences tab")
        }

    }
}
