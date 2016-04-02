//
//  FeedTableViewCell.swift
//  Fandomm
//
//  Created by Simon Narang on 3/30/16.
//  Copyright © 2016 Simon Narang. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    
    //IBOUTLETS
    @IBOutlet weak var feedText: UITextView!
    @IBOutlet weak var feedImage: UIImageView!
    @IBOutlet weak var feedUsernameOutlet: UIButton!
    
    @IBAction func feedUsername(sender: AnyObject) {
        
        feedText.font = UIFont(name: "ArialMT", size: 20)

    }
    
    override func awakeFromNib() {
        
        feedText.font = UIFont(name: "ArialMT", size: 20)
    }
}
