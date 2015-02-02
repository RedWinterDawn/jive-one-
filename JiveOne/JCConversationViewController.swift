//
//  JCConversationViewController.swift
//  JiveOne
//
//  Created by Robert Barclay on 1/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

import UIKit;

class JCConversationViewController: UIViewController, JCMessageBarViewDelegate {
    
    var conversationId:String?
    
//    @IBOutlet weak var messageBarBaseConstraint:NSLayoutConstraint?
//    @IBOutlet weak var messageTextView:HPGrowingTextView?
//    @IBOutlet weak var messageTextViewHeightConstraint:NSLayoutConstraint?
//    @IBOutlet weak var sendBtn:UIButton?
//    
//    private var _defaultMessageTextHeightConstraint:CGFloat?
//    
//    private var conversationTableViewController:JCConversationTableViewController?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        _defaultMessageTextHeightConstraint = self.messageTextViewHeightConstraint?.constant
//    }
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        self.registerForKeyboardNotifications()
//    }
//    
//    override func viewDidDisappear(animated: Bool) {
//        super.viewWillDisappear(animated)
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }
//    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.destinationViewController.isKindOfClass(JCConversationTableViewController) {
//            conversationTableViewController = segue.destinationViewController as? JCConversationTableViewController
//        }
//    }
//    
//    private func registerForKeyboardNotifications() {
//        let notificationCenter = NSNotificationCenter.defaultCenter()
//        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
//        notificationCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
//    }
//    
//    private func animateMessageBarWithKeyboard(notification: NSNotification) {
//        
//        let userInfo = notification.userInfo!
//        let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
//        let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as Double
//        let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as UInt
//        if notification.name == UIKeyboardWillShowNotification {
//            messageBarBaseConstraint?.constant = -keyboardSize.height  // move up
//            conversationTableViewController?.tableViewScrollToBottomAnimated(true)
//        }
//        else {
//            messageBarBaseConstraint?.constant = 0 // move down
//        }
//        
//        view.setNeedsUpdateConstraints()
//        
//        let options = UIViewAnimationOptions(curve << 16)
//        UIView.animateWithDuration(duration, delay: 0, options: options,
//            animations: {
//                self.view.layoutIfNeeded()
//            },
//            completion: nil
//        )
//    }
//    
//    func keyboardWillShow(notification: NSNotification) {
//        animateMessageBarWithKeyboard(notification)
//    }
//    
//    func keyboardWillHide(notification: NSNotification) {
//        animateMessageBarWithKeyboard(notification)
//    }
//    
//    func messageBarTextView(textView: UITextView!, willChangeHeight height: CGFloat) {
//        self.view.setNeedsUpdateConstraints()
//    }
//    
//    func messageBarTextView(textView: UITextView!, didChangeHeight height: CGFloat) {
//        self.view.layoutIfNeeded()
//    }
//    
//    @IBAction func sendMessage(sender: UIButton) {
//        let context = NSManagedObjectContext.MR_defaultContext()
//        let conversation:Conversation = Conversation.MR_createInContext(context) as Conversation
//        conversation.text = self.messageTextView?.text;
//        conversation.jiveUserId = JCAuthenticationManager.sharedInstance().jiveUserId
//        conversation.read = true
//        conversation.date = NSDate()
//        self.messageTextView?.text = "";
//        
//        //FIXME: get the real conversationId as part of the upload
//        conversation.conversationId = String(format: "%i", Conversation.MR_countOfEntities())
//        
//        context.MR_saveToPersistentStoreWithCompletion { (success:Bool, error:NSError!) -> Void in
//            
//            if success {
//                //TODO: upload to the server here.
//                
//                //self.conversationTableViewController?.scrollToBottom(yes)
//            } else {
//                
//            }
//        }
//    }
}
