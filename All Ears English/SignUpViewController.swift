//
//  SignUpViewController.swift
//  All Ears English
//
//  Created by Jay Park on 6/25/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import StoreKit

protocol SignUpViewControllerDelegate:class {
    func signUpViewControllerDelegateDidFinish(signupViewController:SignUpViewController)
    func signUpViewControllerDelegateDidCancel(signupViewController:SignUpViewController)
}

class SignUpViewController: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var usernameTextField:UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    @IBOutlet weak var errorLabel: UILabel! {
        didSet {
            self.errorLabel.isHidden = true
        }
    }
    @IBOutlet weak var signUpButton: UIButton!
    
    weak var delegate:SignUpViewControllerDelegate?
    var subscriptionSKProduct:SKProduct?
    
    //Used to move the view in response to the keyboard
    var currentEditingField:UITextField?
    var keyboardIsShowing = false
    var viewDisplacementFromKeyboard:CGFloat = 0
    var keyboardRect:CGRect = CGRect.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.endEditing))
        self.view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.firstNameTextField.delegate = self
        self.lastNameTextField.delegate = self
        self.usernameTextField.delegate = self
        self.passwordTextField.delegate = self
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    @IBAction func signUpPressed(_ sender:Any) {
        guard let subscriptionProduct = self.subscriptionSKProduct else {
            self.errorLabel.isHidden = false
            self.errorLabel.text = "An error occurred"
            return
        }
        
        self.errorLabel.isHidden = true
        
        guard let firstName = self.firstNameTextField.text,
            firstName.isEmpty == false else {
                self.errorLabel.isHidden = false
                self.errorLabel.text = "Please enter a first name"
                return
        }
        
        guard let lastName = self.lastNameTextField.text,
            lastName.isEmpty == false else {
                self.errorLabel.isHidden = false
                self.errorLabel.text = "Please enter a last name"
                return
        }
        
        guard let username = self.usernameTextField.text,
            username.isEmpty == false else {
                self.errorLabel.isHidden = false
                self.errorLabel.text = "Please enter a username"
                return
        }
        guard let password = self.passwordTextField.text,
            password.isEmpty == false else {
                self.errorLabel.isHidden = false
                self.errorLabel.text = "Please enter a password"
                return
        }
        
        self.signUpButton.isEnabled = false
        Auth.auth().createUser(withEmail: username, password: password) { (result, error) in
            if let error = error {
                self.signUpButton.isEnabled = true
                self.errorLabel.isHidden = false
                self.errorLabel.text = error.localizedDescription
            }
            //success
            else if result?.user != nil {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = "\(firstName) \(lastName)"
                changeRequest?.commitChanges { (error) in
                }
                
                IAPStore.store.purchaseProduct(subscriptionProduct, completion: { (success, error) in
                    self.signUpButton.isEnabled = true
                    if error != nil {
                        self.errorLabel.isHidden = false
                        self.errorLabel.text = "There was an error purchasing your subscription"
                    }
                    else {
                        self.delegate?.signUpViewControllerDelegateDidFinish(signupViewController: self)
                    }
                })
            }
            else {
                self.signUpButton.isEnabled = true
                self.errorLabel.isHidden = false
                self.errorLabel.text = "An error occurred"
            }
        }
    }
    
    @IBAction func cancelPressed(_ sender:Any) {
        self.delegate?.signUpViewControllerDelegateDidCancel(signupViewController: self)
    }
}

//MARK: keyboard management
extension SignUpViewController:UITextFieldDelegate {
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        self.keyboardRect = keyboardFrame.cgRectValue
        
        self.adjustViewForNewInputField()
    }
    
    func adjustViewForNewInputField() {
        guard let inputField = self.currentEditingField,
            inputField.frame.intersects(self.keyboardRect) == true else {
                return
        }
        
        let convertedInputOrigin = inputField.convert(inputField.frame.origin, to:self.view)
        let targetY:CGFloat = self.view.bounds.size.height / 3.0
        let yDelta = convertedInputOrigin.y - targetY
        
        //Prevent extending beyond the bottom of the view
        if yDelta > self.keyboardRect.height {
            self.viewDisplacementFromKeyboard = self.keyboardRect.height
        }
        else {
            self.viewDisplacementFromKeyboard = yDelta
        }
        
        UIView.animate(withDuration: 0.25) {
            self.view.frame.origin.y = self.viewDisplacementFromKeyboard * -1
            self.view.layoutIfNeeded()
        }
        
        self.keyboardIsShowing = true
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.keyboardIsShowing {
            self.viewDisplacementFromKeyboard = 0
            UIView.animate(withDuration: 0.2) {
                self.view.frame.origin.y = self.viewDisplacementFromKeyboard
                self.view.layoutIfNeeded()
            }
            self.keyboardIsShowing = false
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.currentEditingField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.firstNameTextField {
            self.lastNameTextField.becomeFirstResponder()
        }
        else if textField == self.lastNameTextField {
            self.usernameTextField.becomeFirstResponder()
        }
        else if textField == self.usernameTextField {
            self.passwordTextField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return false
    }
}
