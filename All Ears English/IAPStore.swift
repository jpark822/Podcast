//
//  IAPStore.swift
//  All Ears English
//
//  Created by Jay Park on 11/10/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import Foundation

public enum IAPStore {
    
    public static let monthlyPass = "com.purchase.allearsenglish.sub.monthlywithintro"
    public static let yearlyPass = "com.purchase.allearsenglish.sub.yearwithintro"
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [IAPStore.monthlyPass, IAPStore.yearlyPass]
    
    public static let store = IAPHelper(productIdentifiers: IAPStore.productIdentifiers)
}
