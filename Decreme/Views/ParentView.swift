PaymentSheetView(
    total: total,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    ppn: ppn,
    client: client,
    items: items,
    buyerName: buyerName,
    buyerPhone: buyerPhone,
    notes: notes,
    onPaymentComplete: { paymentMethod in
        // Handle payment completion
    },
    onClearCart: {
        // Handle cart clearing here
        // For example:
        items.removeAll()
        UserDefaults.standard.removeObject(forKey: "cartItems")
        UserDefaults.standard.synchronize()
    }
) 