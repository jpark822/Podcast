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
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var usernameTextField:UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    @IBOutlet weak var errorLabel: UILabel! {
        didSet {
            self.errorLabel.isHidden = true
        }
    }
    //Used to move the view in response to the keyboard
    var currentEditingField:UITextField?
    var keyboardIsShowing = false
    var viewDisplacementFromKeyboard:CGFloat = 0
    var keyboardRect:CGRect = CGRect.zero
    
    weak var delegate:LoginUpViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.endEditing))
        self.view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.usernameTextField.delegate = self
        self.passwordTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    @IBAction func loginPressed(_ sender:Any) {
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
        
        self.errorLabel.isHidden = true
        self.loginButton.isEnabled = false
        Auth.auth().signIn(withEmail: username, password: password) { (result, error) in
            if let error = error {
                self.errorLabel.isHidden = false
                self.errorLabel.text = "Please check your username and password"
                self.loginButton.isEnabled = true
                return
            }
            else if result?.user != nil {
                IAPStore.store.restoreCompletedTransactions {(success, error) in 
                    ServiceManager.sharedInstace.checkForValidSubscription(completion: { (hasValidSub, error) in
                        self.loginButton.isEnabled = true
                        self.delegate?.loginViewControllerDelegateDidFinish(loginViewController: self)
                    })
                }
            }
            else {
                self.errorLabel.isHidden = false
                self.errorLabel.text = "An error occurred"
                self.loginButton.isEnabled = true
            }
        }
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        let forgotPasswordVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "ForgotPasswordViewControllerId") as! ForgotPasswordViewController
        self.navigationController?.pushViewController(forgotPasswordVC, animated: true)
    }
    
    @IBAction func cancelPressed(_ sender:Any) {
        self.delegate?.loginViewControllerDelegateDidCancel(loginViewController: self)
    }
    
    static func loginViewControllerWithNavigation(delegate:LoginUpViewControllerDelegate?) -> UINavigationController {
        let loginVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LoginViewControllerId") as! LoginViewController
        loginVC.delegate = delegate
        let navController = UINavigationController(rootViewController: loginVC)
        return navController
    }
}

//MARK: keyboard management
extension LoginViewController:UITextFieldDelegate {
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
        if textField == self.usernameTextField {
            self.passwordTextField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return false
    }
}
