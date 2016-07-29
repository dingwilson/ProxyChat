//
//  MainMessageViewController.swift
//  ProxyChat
//
//
//  Copyright © 2016 Wilson Ding. All rights reserved.
//


import UIKit
import MultipeerConnectivity
import JSQMessagesViewController

class ViewController: JSQMessagesViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor(red: 15/255, green: 135/255, blue: 255/255, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.lightGrayColor())
    var messages = [JSQMessage]()
    
    let serviceType = "ProxyChat"
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func setup(){
        self.senderId = UIDevice.currentDevice().identifierForVendor?.UUIDString
        self.senderDisplayName = UIDevice.currentDevice().identifierForVendor?.UUIDString
        
        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        self.browser = MCBrowserViewController(serviceType:serviceType, session:self.session)
        
        self.browser.delegate = self;
        
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType, discoveryInfo:nil, session:self.session)
        self.assistant.start()
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateChat(text : String!, fromPeer peerID: MCPeerID) {
        var name : String
        
        switch peerID {
        case self.peerID:
            name = "Me"
        default:
            name = peerID.displayName
        }
        
        let currentDate = NSDate()
        let message = JSQMessage(senderId: name, senderDisplayName: name, date: currentDate, text: text)
        self.messages += [message]
        self.finishSendingMessage()
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
    }
    
    func browserViewControllerDidFinish( browserViewController: MCBrowserViewController)  {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled( browserViewController: MCBrowserViewController)  {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID)  {
        dispatch_async(dispatch_get_main_queue()) {
            let msg = NSString(data: data, encoding: NSUTF8StringEncoding)
            self.updateChat(String(msg!), fromPeer: peerID)
        }
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress)  {
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?)  {
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID)  {
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState)  {
    }
    
}

extension ViewController {
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let data = self.collectionView(self.collectionView, messageDataForItemAtIndexPath: indexPath)
        if (self.senderDisplayName == data.senderDisplayName()) {
            return nil
        }
        return NSAttributedString(string: data.senderDisplayName())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let data = self.collectionView(self.collectionView, messageDataForItemAtIndexPath: indexPath)
        if (self.senderDisplayName == data.senderDisplayName()) {
            return 0.0
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.row]
        return data
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didDeleteMessageAtIndexPath indexPath: NSIndexPath!) {
        self.messages.removeAtIndex(indexPath.row)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return self.outgoingBubble
        default:
            return self.incomingBubble
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
}

extension ViewController {
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        self.messages += [message]
        self.finishSendingMessage()
        
        let msg = text!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        do {
            try self.session.sendData(msg!, toPeers: self.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("Error")
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        self.presentViewController(self.browser, animated: true, completion: nil)
    }
}
