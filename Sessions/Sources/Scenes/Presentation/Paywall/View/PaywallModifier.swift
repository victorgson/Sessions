import SwiftUI
import RevenueCatUI
import RevenueCat

struct PaywallIfNeededModifier: ViewModifier {
    var requiredEntitlementIdentifier: String
    var onPurchaseCompleted: ((CustomerInfo) -> Void)?
    var onRestoreCompleted: ((CustomerInfo) -> Void)?

    func body(content: Content) -> some View {
        content
            .presentPaywallIfNeeded(
                requiredEntitlementIdentifier: requiredEntitlementIdentifier,
                purchaseCompleted: { customerInfo in
                    onPurchaseCompleted?(customerInfo)
                },
                restoreCompleted: { customerInfo in
                    onRestoreCompleted?(customerInfo)
                }
            )
    }
}

extension View {
    @ViewBuilder
    func paywallIfNeeded(
        entitlement: String = "Sessions Pro",
        shouldPresent: Bool = true,
        onPurchaseCompleted: ((CustomerInfo) -> Void)? = nil,
        onRestoreCompleted: ((CustomerInfo) -> Void)? = nil
    ) -> some View {
        if shouldPresent {
            self.modifier(
                PaywallIfNeededModifier(
                    requiredEntitlementIdentifier: entitlement,
                    onPurchaseCompleted: onPurchaseCompleted,
                    onRestoreCompleted: onRestoreCompleted
                )
            )
        } else {
            self
        }
    }
}
