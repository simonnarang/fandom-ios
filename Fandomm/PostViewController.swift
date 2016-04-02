//
//  PostViewController.swift
//  Fandomm
//
//  Created by Simon Narang on 11/28/15.
//  Copyright © 2015 Simon Narang. All rights reserved.
//

import UIKit
import MobileCoreServices

class PostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var userFandoms = [AnyObject]()
    var usernameTwoTextThree = String()
    override func viewDidLoad() {
        super.viewDidLoad()
        print(userFandoms)
        print("islife")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueTwo" {
            let destViewContOne: ShareLinkViewController = segue.destinationViewController as! ShareLinkViewController
            destViewContOne.usernameThreeTextOne = self.usernameTwoTextThree
            destViewContOne.userFandoms = self.userFandoms
        }else if segue.identifier == "segueFour" {
            let desViewContThree: ShareCameraViewController = segue.destinationViewController as! ShareCameraViewController
            desViewContThree.userFandoms = self.userFandoms
        }else if segue.identifier == "segueFive" {
            let destViewContTwo: ShareGalleryViewController = segue.destinationViewController as! ShareGalleryViewController
            destViewContTwo.userFandoms = self.userFandoms
        }else {
        print("there is an undocumented segue form the post tab")
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
