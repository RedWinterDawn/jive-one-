//
//  JCConversationTableViewController.swift
//  JiveOne
//
//  Created by Robert Barclay on 1/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

import UIKit

class JCConversationTableViewController: JCFetchedResultsTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
    }
}
