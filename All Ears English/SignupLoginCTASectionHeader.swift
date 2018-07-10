//
//  SignupLoginCTASectionHeader.swift
//  All Ears English
//
//  Created by Jay Park on 7/9/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit

protocol SignupLoginCTASectionHeaderDelegate:class {
    func signupLoginCTASectionHeaderDidPressLogin(header:SignupLoginCTASectionHeader)
    func signupLoginCTASectionHeaderDidPressSignUp(header:SignupLoginCTASectionHeader)
}

class SignupLoginCTASectionHeader: UITableViewHeaderFooterView {
    
    weak var delegate:SignupLoginCTASectionHeaderDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    @IBAction func signupPressed(_ sender: Any) {
        self.delegate?.signupLoginCTASectionHeaderDidPressSignUp(header: self)
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        self.delegate?.signupLoginCTASectionHeaderDidPressLogin(header: self)
    }
}
