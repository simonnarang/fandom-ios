//
//  ShareLinkViewController.swift
//  Fandomm
//
//  Created by Simon Narang on 11/29/15.
//  Copyright © 2015 Simon Narang. All rights reserved.
//

import UIKit

class ShareLinkViewController: UIViewController {
    
    //vars
    var shareLinkk = String()
    var fandommcount = 0
    var usernameThreeTextOne = String()
    var userFandoms = [AnyObject]()
    
    //IBOUTLETS
    @IBOutlet weak var shareLink: UITextField!
    
    @IBAction func shareLinkButton(sender: AnyObject) {
        
        //make user inputted text the text to share
        self.shareLinkk = self.shareLink.text!
        let linkShareActionSheetMenu = UIAlertController(title: nil, message: "which fandoms do you want to share this with?", preferredStyle: .ActionSheet)
        let backAction = UIAlertAction(title: "back", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled Link Share")
        })
        linkShareActionSheetMenu.addAction(backAction)
        performSegueWithIdentifier("segueThree", sender: nil)
        
    }
    
    //startup junk
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tap screen to close keyboard in case it doesnt close some other way
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        fandommcount = 0
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueThree" {
            
            let destViewContOne: ShareToFandomNavigationViewController = segue.destinationViewController as! ShareToFandomNavigationViewController
            destViewContOne.usernameThreeTextOne = self.usernameThreeTextOne
            destViewContOne.shareLinky = self.shareLinkk
            destViewContOne.userFandoms = self.userFandoms
            
        }else {
            
            print("there is an undocumented segue form the sharelink tab")
            
        }
        
    }
    func dismissKeyboard() {
        
        view.endEditing(true)
    }
}
