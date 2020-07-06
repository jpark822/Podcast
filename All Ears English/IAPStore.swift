import Foundation

public enum IAPStore {
    
    public static let monthlyPass = "com.purchase.allearsenglish.sub.monthlywithintro"
    public static let yearlyPass = "com.purchase.allearsenglish.sub.yearwithintro"
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [IAPStore.monthlyPass, IAPStore.yearlyPass]
    
    public static let store = IAPHelper(productIdentifiers: IAPStore.productIdentifiers)
}
