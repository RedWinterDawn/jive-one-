//
//  JCChatTableViewController.swift
//  JiveOne
//
//  Created by Robert Barclay on 1/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

import UIKit

let ConversationMessageCellReuseIdentifer = "ConversationMessageCell"
let SMSMessageCellReuseIdentifer = "SMSMessageCell"

class JCChatTableViewController: JCFetchedResultsTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: ConversationMessageCellReuseIdentifer)
        self.tableView.dataSource = self
    }
    
    
    override func tableView(tableView: UITableView!, cellForObject object: NSObjectProtocol!, atIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        if object.isKindOfClass(Conversation) {
            let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(ConversationMessageCellReuseIdentifer) as UITableViewCell
            configureCell(cell, withObject: object);
            return cell
        } else if object.isKindOfClass(SMSMessage) {
            let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(SMSMessageCellReuseIdentifer) as UITableViewCell
            configureCell(cell, withObject: object);
            return cell
        }
        return nil
    }
    
    override func configureCell(cell: UITableViewCell!, withObject object: NSObjectProtocol!) {
        if object.isKindOfClass(Conversation){
            
        }
        else if object.isKindOfClass(SMSMessage) {
            
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "goToChat" {
            var DestViewController : JCConversationTableViewController  = segue.destinationViewController as JCConversationTableViewController
        }
        
    }
    
}

