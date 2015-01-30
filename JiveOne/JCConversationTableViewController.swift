//
//  JCConversationTableViewController.swift
//  JiveOne
//
//  Created by Robert Barclay on 1/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

import UIKit

let OutgoingCellReuseIdentifier = "OutgoingCell"
let IncomingCellReuseIdentifier = "IncomingCell"

class JCConversationTableViewController: JCFetchedResultsTableViewController {

    var conversationId:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        var fetchRequest:NSFetchRequest
        if (conversationId? != nil) {
            fetchRequest = Message.MR_requestAllWhere("conversationId", isEqualTo: conversationId, inContext: self.managedObjectContext)
        } else {
            fetchRequest = Message.MR_requestAllInContext(self.managedObjectContext);
        }
        
        let sortDescriptor:NSSortDescriptor = NSSortDescriptor(key: "date", ascending:false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.includesSubentities = true
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func configureCell(cell: UITableViewCell!, withObject object: NSObjectProtocol!) {
        let message = object as Message
       
        cell.textLabel?.text = message.text;
        cell.detailTextLabel?.text = message.timestamp.stringValue
    }
    
    override func tableView(tableView: UITableView!, cellForObject object: NSObjectProtocol!, atIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        if object.isKindOfClass(Conversation) {
            let conversation:Conversation = object as Conversation
            var cell:UITableViewCell
            if conversation.jiveUserId == JCAuthenticationManager.sharedInstance().jiveUserId {
                cell = self.tableView.dequeueReusableCellWithIdentifier(OutgoingCellReuseIdentifier) as UITableViewCell
            } else {
                cell = self.tableView.dequeueReusableCellWithIdentifier(IncomingCellReuseIdentifier) as UITableViewCell
            }
            configureCell(cell, withObject: object)
            return cell
        }
        return nil;
    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let message = self.objectAtIndexPath(indexPath) as Message
        let cell = self.tableView.dequeueReusableCellWithIdentifier(OutgoingCellReuseIdentifier) as UITableViewCell
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 66.0

        return tableView.rowHeight
    }
}
