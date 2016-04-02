//
//  TabBarViewController.swift
//  Fandomm
//
//  Created by Simon Narang on 11/29/15.
//  Copyright © 2015 Simon Narang. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    //vars
    var usernameTwo = String()
    var userFandoms = [AnyObject]()
    var number = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //change tint of tab bar to match logo
        self.tabBar.tintColor = UIColor.purpleColor()
        
        //give feed user info
        let dataTransferViewControllerOne = (self.viewControllers?[0] as! UINavigationController).viewControllers[0] as! FeedTableViewController
        dataTransferViewControllerOne.usernameTwoTextOne = usernameTwo
        dataTransferViewControllerOne.number = self.number
        
        //give search user info
        let dataTransferViewControllerTwo = (self.viewControllers?[1] as! UINavigationController).viewControllers[0] as! SearchTableViewController
        dataTransferViewControllerTwo.usernameTwoTextTwo = usernameTwo
        
        //give post user info
        let dataTransferViewControllerThree = (self.viewControllers?[2] as! UINavigationController).viewControllers[0] as! PostViewController
        dataTransferViewControllerThree.usernameTwoTextThree = usernameTwo
        dataTransferViewControllerThree.userFandoms = self.userFandoms
        
        //give profile user info
        let dataTransferViewControllerFour = (self.viewControllers?[3] as! UINavigationController).viewControllers[0] as! ProfileViewController
        dataTransferViewControllerFour.usernameTwoTextFour = usernameTwo
        
        //give prefernces user info
        let dataTransferViewControllerFive = (self.viewControllers?[4] as! UINavigationController).viewControllers[0] as! PreferecesTableViewController
        dataTransferViewControllerFive.userameTwoTextFive = usernameTwo
    }
    
    //startup junk
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
