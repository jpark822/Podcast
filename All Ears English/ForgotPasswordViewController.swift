//
//  ForgotPasswordViewController.swift
//  All Ears English
//
//  Created by Jay Park on 7/9/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.endEditing))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    @IBAction func resetPasswordPressed(_ sender: Any) {
    }
    
}
