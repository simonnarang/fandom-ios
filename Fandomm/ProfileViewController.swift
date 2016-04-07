//
//  ProfileViewController.swift
//  Fandomm
//
//  Created by Simon Narang on 11/21/15.
//  Copyright © 2015 Simon Narang. All rights reserved.
//

import UIKit
class ProfileViewController: UIViewController {
    
    //vars
    var usernameTwoTextFour = String()
    
    //IBOUTLETS
    @IBOutlet weak var usernameTwo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //lebel user's username
        usernameTwo.text = "@" + usernameTwoTextFour
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.purpleColor()]
        self.navigationController?.navigationBar.tintColor = UIColor.purpleColor()
        self.navigationController?.navigationBar.translucent = true
        if let font = UIFont(name: "Lato-Light.ttf", size: 34) {
            UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: font]
        }

        
    }
    
    //startup junk
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
