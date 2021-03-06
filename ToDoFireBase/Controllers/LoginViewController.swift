//
//  ViewController.swift
//  ToDoFireBase
//
//  Created by mac on 4/20/19.
//  Copyright © 2019 mac. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInUIDelegate {
    
    let segueIdentifier = "tasksSegue"
    var ref: DatabaseReference!
    
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference(withPath: "users")
        
        NotificationCenter.default.addObserver(self, selector: #selector(kbDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        warningLabel.alpha = 0
        
        // If we are logged in, we switch to task view
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if user != nil {
                self?.performSegue(withIdentifier: (self?.segueIdentifier)!, sender: nil)
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GIDSignIn.sharedInstance()?.uiDelegate = self
        GIDSignIn.sharedInstance()?.delegate = self
        
        // Clear fields
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @objc func kbDidShow(notifcation: Notification) {
        guard let userInfo = notifcation.userInfo else { return }
        let kbFrameSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        (self.view as! UIScrollView).contentSize = CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height + kbFrameSize.height)
        (self.view as! UIScrollView).scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbFrameSize.height, right: 0)
    }
    
    @objc func kbDidHide() {
        (self.view as! UIScrollView).contentSize = CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        
    }
    
    // Display text of warning with animation
    func displayWarningLabel(widthText text: String) {
        warningLabel.text = text
        UIView.animate(withDuration: 3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseOut], animations: { [weak self] in
            self?.warningLabel.alpha = 1
        }) { complete in
            self.warningLabel.alpha = 0
        }
    }
    
    // Login with Email
    @IBAction func loginTapped(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text, email != "", password != "" else {
            displayWarningLabel(widthText: "Info is Incorrect")
            return
        }
        // Auth with email and password
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] user, error in
            if error != nil {
                self?.displayWarningLabel(widthText: "Error occured")
                return
            }
            
            if user != nil {
                self?.performSegue(withIdentifier: (self?.segueIdentifier)!, sender: nil)
                return
            }
            self?.displayWarningLabel(widthText: "No such user")
        }
        
    }
    
    // Register new user
    @IBAction func registerTapped(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text, email != "", password != "" else {
            displayWarningLabel(widthText: "Info is Incorrect")
            return
        }
        // Create new user
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] user, error in
            
            guard error == nil, user != nil else {
                print(error!.localizedDescription)
                return
            }
            //Write data of email in the user.uid
            let userRef = self?.ref.child((user?.user.uid)!)
            userRef?.setValue(["email": user?.user.email])
        }
    }
    
    // Login with Google
    @IBAction func googleSignInTapped(_ sender: Any) {
        GIDSignIn.sharedInstance()?.signIn()
    }
    
}

extension LoginViewController: GIDSignInDelegate {
    //Authenticate with Firebase (Google)
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        guard error == nil, user != nil else {
            print(error!.localizedDescription)
            return
        }
        
        guard let authentication = user.authentication else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        // Authenticate with Firebase using the credential
        Auth.auth().signInAndRetrieveData(with: credential) { [weak self] result, error in
            
            if error != nil {
                self?.displayWarningLabel(widthText: "Failed to sign in with error:")
                return
            }
            
            guard let uid = result?.user.uid else { return }
            guard let email = result?.user.email else { return }
            guard let username = result?.user.displayName else { return }
            let userRef = self?.ref.child(uid)
            userRef?.updateChildValues(["email": email, "username": username])
            self?.performSegue(withIdentifier: (self?.segueIdentifier)!, sender: nil)
            print("Sign in with Google")
        }
    }
}
