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
        
    }
    
    //startup junk
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
