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
    func loginViewControllerDelegateDidFinish(signupViewController:LoginViewController)
    func loginViewControllerDelegateDidCancel(signupViewController:LoginViewController)
}

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField:UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    weak var delegate:LoginUpViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                self.delegate?.loginViewControllerDelegateDidFinish(signupViewController: self)
            }
            else {
                self.errorLabel.text = "An error occurred"
            }
        }
    }
    
    @IBAction func cancelPressed(_ sender:Any) {
        self.delegate?.loginViewControllerDelegateDidCancel(signupViewController: self)
    }
    
}
