/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit

class GroceryListTableViewController: UITableViewController {

  // MARK: Constants
  let ListToUsers = "ListToUsers"
  let ref = Firebase(url: "https://grocerchat.firebaseio.com/grocery-items")
  let usersRef = Firebase(url: "https://grocerchat.firebaseio.com/online")
  
  // MARK: Properties 
  var items = [GroceryItem]()
  var user: User!
  var userCountBarButtonItem: UIBarButtonItem!
  
  // MARK: UIViewController Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    // Set up swipe to delete
    tableView.allowsMultipleSelectionDuringEditing = false
    
    // User Count
    userCountBarButtonItem = UIBarButtonItem(title: "1", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("userCountButtonDidTouch"))
    userCountBarButtonItem.tintColor = UIColor.whiteColor()
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
/////*----LOGGING: retrieve data in Firebase by attaching asynchronous listener to a reference...
////the code listens for .Value (an event type) and notified of the change via a closure.*/
////    
//////1. Attach a listener to receive updates whenever the grocery-items endpoint is modified.
//    ref.observeEventType(.Value, withBlock: { snapshot in
////
//////2. Store the latest version of the data in a local variable inside the listener’s closure.
//    var newItems = [GroceryItem]()
////
//////3. The listener’s closure returns a snapshot of the latest set of data.
//    for item in snapshot.children {

//      let groceryItem = GroceryItem(snapshot: item as! FDataSnapshot)
//  newItems.append(groceryItem)
////    }
    
    
//SORTING: querying through items in FireBase
      self.ref.queryOrderedByChild("completed").observeEventType(.Value, withBlock: { snapshot in
        var newItems = [GroceryItem]()
        for item in snapshot.children {
          let groceryItem = GroceryItem(snapshot: item as! FDataSnapshot)
          newItems.append(groceryItem)
        }
        
    

    self.items = newItems
    self.tableView.reloadData()
    
      })
//MONITORING ONLINE USERS:
    ref.observeAuthEventWithBlock { [unowned self] authData in
      if let authData = authData {
        self.user = User(authData: authData) // setting username in cell**
        let currentUserRef = self.usersRef.childByAppendingPath(self.user.uid)
        currentUserRef.setValue(self.user.email)
        /*This removes the value at the reference’s location after the connection to
        Firebase closes, for instance when a user quits your app. */
        currentUserRef.onDisconnectRemoveValue()
      }
    }
    
    usersRef.observeEventType(.Value, withBlock: { (snapshot: FDataSnapshot!) in
      if snapshot.exists() {
        self.userCountBarButtonItem?.title = snapshot.childrenCount.description
        
      } else {
        self.userCountBarButtonItem?.title = "0"
      }
    })
    
  }
  
  

  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    
  }
  
  // MARK: UITableView Delegate methods
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell") as UITableViewCell!
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    // Determine whether the cell is checked
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      // Find the snapshot and remove the value
      let groceryItem = items[indexPath.row]
      groceryItem.ref?.removeValue()
      tableView.reloadData()
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
  // Find the cell tapped, get the groceryItem
    let cell = tableView.cellForRowAtIndexPath(indexPath)!
    var groceryItem = items[indexPath.row]
  //Negate the "completion" status
    let toggledCompletion = !groceryItem.completed
    
    // Determine whether the cell is checked (visual presentation)
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    
    //This method updates values instead of overriding like setValue.
    
    groceryItem.ref?.updateChildValues([
      "completed" : toggledCompletion
      ])
    tableView.reloadData()
  }
  
  func toggleCellCheckbox(cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = UITableViewCellAccessoryType.None
      cell.textLabel?.textColor = UIColor.blackColor()
      cell.detailTextLabel?.textColor = UIColor.blackColor()
    } else {
      cell.accessoryType = UITableViewCellAccessoryType.Checkmark
      cell.textLabel?.textColor = UIColor.grayColor()
      cell.detailTextLabel?.textColor = UIColor.grayColor()
    }
  }
  
  // MARK: Add Item
  
  @IBAction func addButtonDidTouch(sender: AnyObject) {
    // Alert View for input
    let alert = UIAlertController(title: "Grocery Item",
      message: "Add an Item",
      preferredStyle: .Alert)
    
    let saveAction = UIAlertAction(title: "Save",
      style: .Default) { (action: UIAlertAction) -> Void in
    
      let textField = alert.textFields![0] 
      let groceryItem = GroceryItem(name: textField.text!, addedByUser: self.user.email, completed: false)
      //this is where you're saving the child grocery item based on text input
      let groceryItemRef = self.ref.childByAppendingPath(textField.text?.lowercaseString)
      //set the value of object to its key (the child ref)
      groceryItemRef.setValue(groceryItem.toAnyObject())
      
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
      style: .Default) { (action: UIAlertAction) -> Void in
    }
    
    alert.addTextFieldWithConfigurationHandler {
      (textField: UITextField!) -> Void in
    }
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    presentViewController(alert,
      animated: true,
      completion: nil)
  }
  
  func userCountButtonDidTouch() {
    performSegueWithIdentifier(ListToUsers, sender: nil)
  }
  
}
