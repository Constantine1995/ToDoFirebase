//
//  TaskViewController.swift
//  ToDoFireBase
//
//  Created by mac on 4/20/19.
//  Copyright © 2019 mac. All rights reserved.
//

import UIKit
import Firebase
class TaskViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var user: Users!
    var ref: DatabaseReference!
    var task = Array<Task>()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let currentUser = Auth.auth().currentUser else { return }
        user = Users(user: currentUser)
        // Getting the base reference to get to the children
        ref = Database.database().reference(withPath: "users").child(String(user.uid)).child("tasks")
    }
    
    // Get data from Firebase
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ref.observe(.value) { [weak self] snapshot in
            var _tasks = Array<Task>()
            for item in snapshot.children {
                let task = Task(snapshot: item as! DataSnapshot)
                _tasks.append(task)
            }
            self?.task = _tasks
            self?.tableView.reloadData()
        }
    }
    
    // Removing all observers after them loading
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ref.removeAllObservers()
    }
    
    // SignOut from account
    @IBAction func signOutTapped(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print(error.localizedDescription)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return task.count
    }
    
    // MARK: cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let tasks = task[indexPath.row]
        let isCompleted = tasks.completed
        let taskTitle = tasks.title
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = taskTitle
        toggleCompletion(cell, isCompleted: isCompleted)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Remove value from cell-task
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tasks = task[indexPath.row]
            tasks.ref?.removeValue()
        }
    }
    
    // Write checkmark to firebase in task
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let tasks = task[indexPath.row]
        let isCompleted = !tasks.completed
        toggleCompletion(cell, isCompleted: isCompleted)
        tasks.ref?.updateChildValues(["completed" : isCompleted])
    }
    
    // Set accesoryType
    func toggleCompletion(_ cell: UITableViewCell, isCompleted: Bool) {
        cell.accessoryType = isCompleted ? .checkmark : .none
    }
    
    // Write data to Firebase
    @IBAction func addTaped(_ sender: Any) {
        let alertController = UIAlertController(title: "New Task", message: "Add new task", preferredStyle: .alert)
        alertController.addTextField()
        let save = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard  let textField = alertController.textFields?.first, textField.text != "" else { return }
            let task = Task(title: textField.text!, userId: (self?.user.uid)!)
            let taskRef = self?.ref.child(task.title.lowercased())
            taskRef?.setValue(task.convertToDictionary())
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancel)
        alertController.addAction(save)
        
        present(alertController, animated: true, completion: nil)
    }    
}
