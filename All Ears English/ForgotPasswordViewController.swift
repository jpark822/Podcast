//
//  ForgotPasswordViewController.swift
//  All Ears English
//
//  Created by Jay Park on 7/9/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var errorLabel: UILabel! {
        didSet {
            self.errorLabel.isHidden = true
        }
    }
    @IBOutlet weak var usernameTextField: UITextField!
    
    weak var delegate:LoginUpViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.endEditing))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    @IBAction func resetPasswordPressed(_ sender: Any) {
        guard let username = usernameTextField.text else {
            return
        }
        Auth.auth().sendPasswordReset(withEmail:username) { (error) in
            if let error = error {
                self.errorLabel.isHidden = false
                self.errorLabel.text = "There was an error. Please check your email address"
            }
            else {
                self.errorLabel.isHidden = true
                self.dismiss(animated: true)
            }
        }
    }
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}
