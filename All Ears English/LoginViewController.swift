//
//  LoginViewController.swift
//  All Ears English
//
//  Created by Jay Park on 6/26/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

protocol LoginUpViewControllerDelegate:class {
    func loginViewControllerDelegateDidFinish(loginViewController:LoginViewController)
    func loginViewControllerDelegateDidCancel(loginViewController:LoginViewController)
}

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField:UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    @IBOutlet weak var errorLabel: UILabel! {
        didSet {
            self.errorLabel.isHidden = true
        }
    }
    
    weak var delegate:LoginUpViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.endEditing))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    @IBAction func loginPressed(_ sender:Any) {
        guard let username = self.usernameTextField.text,
            username.isEmpty == false else {
                self.errorLabel.text = "Please enter a username"
                return
        }
        guard let password = self.usernameTextField.text,
            password.isEmpty == false else {
                self.errorLabel.text = "Please enter a password"
                return
        }
        Auth.auth().signIn(withEmail: username, password: password) { (result, error) in
            if let error = error {
                self.errorLabel.text = error.localizedDescription
                return
            }
            else if result?.user != nil {
                self.delegate?.loginViewControllerDelegateDidFinish(loginViewController: self)
            }
            else {
                self.errorLabel.text = "An error occurred"
            }
        }
    }
    
    @IBAction func cancelPressed(_ sender:Any) {
        self.delegate?.loginViewControllerDelegateDidCancel(loginViewController: self)
    }
    
}
