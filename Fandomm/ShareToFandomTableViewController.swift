//
//  ShareToFandomTableViewController.swift
//  Fandomm
//
//  Created by Simon Narang on 1/9/16.
//  Copyright © 2016 Simon Narang. All rights reserved.
//

import UIKit

class ShareToFandomTableViewController: UITableViewController {
    
    //redislabs redis server hosted @17342
    let redisClient:RedisClient = RedisClient(host:"pub-redis-17342.us-east-1-4.3.ec2.garantiadata.com", port:17342, loggingBlock:{(redisClient:AnyObject, message:String, severity:RedisLogSeverity) in
        var debugString:String = message
        debugString = debugString.stringByReplacingOccurrencesOfString("\r", withString: "\\r")
        debugString = debugString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
        print("Log (\(severity.rawValue)): \(debugString)")
    })
    
    //vars
    var userFandoms = [AnyObject]()
    var usernameThreeTextOne = String()
    var shareImage = UIImage()
    var shareLinky = String()
    var thearray = [AnyObject]()
    var theUsernamesArray = [String]()
    let delimiter = " -"
    var postFromDB = String()
    var newPost = [String]()
    var number = Int()
    
    
    //make alerts
    let linkShareActionSheetMenu = UIAlertController(title: nil, message: "which fandoms do you want to share this with?", preferredStyle: .ActionSheet)
    let backAction = UIAlertAction(title: "back", style: .Cancel, handler: {
        (alert: UIAlertAction!) -> Void in
        print("Cancelled Text Share")
    })

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tvc not editable
        self.clearsSelectionOnViewWillAppear = false
        
        linkShareActionSheetMenu.addAction(backAction)
        
        //get a certain fandom's posts
        self.redisClient.lRange("thefandomfandom", start: 0, stop: 9999999) { (array, error) in
            
            if error != nil {
            
                print("err(ShareToFandomTableViewController): could not lRange fandom... \(error)")
                
            }else{
            
                for fandommpost in array {
                    
                    self.postFromDB = fandommpost as! String
                    self.newPost = self.postFromDB.componentsSeparatedByString(self.delimiter)
                    self.thearray.append(self.newPost[0])
                    self.theUsernamesArray.append(self.newPost[1])
                    self.number = array.count
                    
                }

                print("succesfully LRANGED fandom in ShareToFandomTableViewController")
                
            }
            
        }
        
        //get user's fandoms
        self.redisClient.lRange("\(self.usernameThreeTextOne)fandoms", start: 0, stop: 99999999, completionHandler: { (array, error) -> Void in
            
            self.userFandoms = array
            
            print("\(self.usernameThreeTextOne)fandoms")
            print("there is an error if \(self.userFandoms) != \(array)")
            
            for fandom in array {
                
                let fandom4actionsheet = UIAlertAction(title: fandom as? String, style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                
                    self.redisClient.lPush(fandom as! String, values: ["\(self.shareLinky) -\(self.usernameThreeTextOne)"], completionHandler: { (int, error) -> Void in
                    
                    if error != nil {
                        
                        print("err(ShareToFandomTableViewController: error LPUSHING text post... \(error))")
                        
                    }else{
                        
                    print("LPUSHED \(self.shareLinky) to \(fandom)")
                        
                    }
                        
                    })
                    
                })
                
                //add fandom found in array to actionsheet so user can select
                self.linkShareActionSheetMenu.addAction(fandom4actionsheet)
            }
           
        })
        
        //present pop up to select fandom to share to
        self.presentViewController(linkShareActionSheetMenu, animated: true, completion: nil)
       
        //networkErrorAlertOne
        let networkErrorAlertOne = UIAlertController(title: "Network troubles...", message: "Sorry about that... Perhaps check the app store to see if you need to update fandom... If not I'm already working on a fix so try again soon", preferredStyle: .Alert)
        
        let networkErrorAlertOneOkButton =  UIAlertAction(title: "☹️okay☹️", style: .Default) { (action) in}
        
        networkErrorAlertOne.addAction(networkErrorAlertOneOkButton)
        
        //noFandomsErrorAlertOne
        let noFandomsErrorAlertOne = UIAlertController(title: "Youre not in any Fandoms!", message: "id recomend searching gor what your interested in and joining it!", preferredStyle: .Alert)
        
        let noFandomsErrorAlertOneOkButton =  UIAlertAction(title: "okay", style: .Default) { (action) in}
        
        let noFandomsErrorAlertOneOkButton2 =  UIAlertAction(title: "search", style: .Default) { (action) in
            
            self.performSegueWithIdentifier("segueSeven", sender: nil)
            
        }
        
        noFandomsErrorAlertOne.addAction(noFandomsErrorAlertOneOkButton)
        
        noFandomsErrorAlertOne.addAction(noFandomsErrorAlertOneOkButton2)
        
        //lRange user's fandoms
        redisClient.lRange("\(self.usernameThreeTextOne)fandoms", start: 0, stop: 99999999) { (array, error) -> Void in
            if error != nil {
                print(error)
                self.presentViewController(networkErrorAlertOne, animated: true) {}
            }else if array == nil {
                print("err(ShareToFandomTableViewController): signed in user(\(self.usernameThreeTextOne)) does not have any fandoms")
                self.presentViewController(noFandomsErrorAlertOne, animated: true) {}
            }else if error == nil{
                print("\(self.usernameThreeTextOne)'s fandoms is/are \(array)")
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userFandoms.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("custom", forIndexPath: indexPath)
        self.redisClient.lRange("\(self.usernameThreeTextOne)fandoms", start: 0, stop: 9999) { (array, error) -> Void in
            if error != nil {
                print("err(ShareToFandomTableViewController): couldnt find fandoms for signed in user")
            }
            cell.textLabel?.text = self.userFandoms[indexPath.row] as? String
        }
        return cell
    }

    
    @IBAction func share(sender: AnyObject) {
        performSegueWithIdentifier("doneSharing", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "doneSharing" {
            
            let destViewContOne: TabBarViewController = segue.destinationViewController as! TabBarViewController
            destViewContOne.thearray = self.thearray
            destViewContOne.theUsernamesArray = self.theUsernamesArray
            destViewContOne.usernameTwo = self.usernameThreeTextOne
            destViewContOne.number = self.number
            
        }else {
            
            print("err(ShareToFandomTableViewController): undocumented segue @prepeareForSegue override")
            
        }

        
    }

}
