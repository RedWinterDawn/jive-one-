//
//  JCChatTableViewController.swift
//  JiveOne
//
//  Created by Robert Barclay on 1/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

import UIKit

let ConversationCellReuseIdentifer = "ConversationCell"

class JCConversationsTableViewController: JCFetchedResultsTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: ConversationCellReuseIdentifer)
        self.tableView.dataSource = self
        
        let fetchRequest:NSFetchRequest = Message.MR_requestAll()
        fetchRequest.includesSubentities = true
        let sortDescriptor:NSSortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        //fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        //fetchRequest.propertiesToGroupBy = ["conversationId"]
        
        let fetchedResultsController:NSFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }

    override func tableView(tableView: UITableView!, cellForObject object: NSObjectProtocol!, atIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        if object.isKindOfClass(Message) {
            let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(ConversationCellReuseIdentifer) as UITableViewCell
            configureCell(cell, withObject: object)
            return cell
        }
        return nil
    }
    
    override func configureCell(cell: UITableViewCell!, withObject object: NSObjectProtocol!) {
        if object.isKindOfClass(Message){
            
        }
    }

//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.destinationViewController.isKindOfClass(JCConversationViewController) {
//            var conversationViewController : JCConversationViewController  = segue.destinationViewController as JCConversationViewController
//            
////            let indexPath: NSIndexPath = self.tableView.indexPathForSelectedRow()!;
////            conversationViewController.conversationId = "1"
//            
//            
//        }
//    }
}

