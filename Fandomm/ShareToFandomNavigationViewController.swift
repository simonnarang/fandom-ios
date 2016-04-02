//
//  ShareToFandomNavigationViewController.swift
//  Fandomm
//
//  Created by Mom on 2/13/16.
//  Copyright © 2016 Simon Narang. All rights reserved.
//

import UIKit

class ShareToFandomNavigationViewController: UINavigationController {
    
    var usernameThreeTextOne = String()
    var shareLinky = String()
    var userFandoms = [AnyObject]()
    var shareImage = UIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dataTransferViewControllerOne = (self.viewControllers[0] as UIViewController) as! ShareToFandomTableViewController
        dataTransferViewControllerOne.usernameThreeTextOne = self.usernameThreeTextOne
        dataTransferViewControllerOne.shareLinky = self.shareLinky
        dataTransferViewControllerOne.shareImage = self.shareImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
