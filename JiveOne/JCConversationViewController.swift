//
//  JCConversationViewController.swift
//  JiveOne
//
//  Created by Robert Barclay on 1/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

import UIKit;

class JCConversationViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var messageBarBaseConstraint:NSLayoutConstraint?
    var conversationId:String?
    
    
    private var conversationTableViewController:JCConversationTableViewController?
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.registerForKeyboardNotifications()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController.isKindOfClass(JCConversationTableViewController) {
            conversationTableViewController = segue.destinationViewController as? JCConversationTableViewController
        }
    }
    
    private func registerForKeyboardNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    private func animateMessageBarWithKeyboard(notification: NSNotification) {
        
        let userInfo = notification.userInfo!
        let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as Double
        let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as UInt
        if notification.name == UIKeyboardWillShowNotification {
            messageBarBaseConstraint?.constant = -keyboardSize.height  // move up
        }
        else {
            messageBarBaseConstraint?.constant = 0 // move down
        }
        
        view.setNeedsUpdateConstraints()
        
        let options = UIViewAnimationOptions(curve << 16)
        UIView.animateWithDuration(duration, delay: 0, options: options,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    func keyboardWillShow(notification: NSNotification) {
        animateMessageBarWithKeyboard(notification)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        animateMessageBarWithKeyboard(notification)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        let context = NSManagedObjectContext.MR_defaultContext()
        let message:Message = Message.MR_createInContext(context) as Message
        message.text = textField.text;
        
        context.MR_saveToPersistentStoreWithCompletion { (success:Bool, error:NSError!) -> Void in
            //TODO: upload to the server here.
        }
        
        
        
        
        return true
    }

}
