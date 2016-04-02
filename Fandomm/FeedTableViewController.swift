//
//  FeedTableViewController.swift
//  Fandomm
//
//  Created by Simon Narang on 11/21/15.
//  Copyright © 2015 Simon Narang. All rights reserved.
//

import UIKit
class FeedTableViewController: UITableViewController {
    
    //vars and lets
    var usernameTwoTextOne = String()
    var thearray = [AnyObject]()
    var theUsernamesArray = [String]()
    var number = Int()
    let delimiter = " -"
    var postFromDB = String()
    var newPost = [String]()
    
    
    //redis connection
    let redisClient:RedisClient = RedisClient(host:"pub-redis-17342.us-east-1-4.3.ec2.garantiadata.com", port:17342, loggingBlock:{(redisClient:AnyObject, message:String, severity:RedisLogSeverity) in
        var debugString:String = message
        debugString = debugString.stringByReplacingOccurrencesOfString("\r", withString: "\\r")
        debugString = debugString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
        print("Log (\(severity.rawValue)): \(debugString)")
    })
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        let fandomLogo = UIImage(named: "fandomlogoicon-1")
        let imageView = UIImageView(image:fandomLogo)
        self.navigationItem.titleView = imageView
        
    }

    //IBOUTLETS
    @IBOutlet weak var GetImage: UIImageView!

    //startup junk
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("custom", forIndexPath: indexPath) as! FeedTableViewCell
        self.redisClient.lRange("thefandomfandom", start: 0, stop: 9999) { (array, error) -> Void in
            if error != nil {
                
                print("err(FeedTableViewController): cellForRow@indexpath func unable to lrange redis db")
                
            }else {
                
                for fandommpost in array {
                        self.postFromDB = fandommpost as! String
                        self.newPost = self.postFromDB.componentsSeparatedByString(self.delimiter)
                        self.thearray.append(self.newPost[0])
                        self.theUsernamesArray.append(self.newPost[1])
                    
                    
                }
            }
            
            cell.feedText.font = UIFont(name: "ArialMT", size: 20)
            cell.feedText.text = self.thearray[indexPath.row] as? String
            cell.feedUsernameOutlet.setTitle(self.theUsernamesArray[indexPath.row], forState: .Normal)
            cell.feedText.font = UIFont(name: "ArialMT", size: 20)
            
        }
        
        return cell
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.number
        
    }

}
