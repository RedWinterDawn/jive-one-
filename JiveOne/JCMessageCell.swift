//
//  JCMessageCell.swift
//  JiveOne
//
//  Created by Robert Barclay on 1/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

import UIKit

class JCMessageCell: JCRecentEventCell {

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    var message:Message? {
        didSet {
            self.recentEvent = message
        }
    }
}
