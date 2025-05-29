//
//  PaymentSheetView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI
import PDFKit
import UIKit
import Supabase

struct PaymentSheetView: View {
    let total: Decimal
    let subtotal: Decimal
    let deliveryFee: Decimal
    let ppn: Decimal
    let client: Client
    let items: [CartItem]
    let buyerName: String
    let buyerPhone: String
    let notes: String
    let onPaymentComplete: (String) -> Void
    let onClearCart: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod = PaymentMethod.cash
    @State private var isProcessing = false
    @State private var showingShareSheet = false
    @State private var invoicePDF: Data?
    @State private var orderNumber: String = "ORD-\(Date().timeIntervalSince1970.rounded())"
    @State private var showingPDFPreview = false
    @State private var error: Error?
    @State private var showingThankYouAlert = false
    
    enum PaymentMethod: String, CaseIterable {
        case cash = "Cash"
        case transfer = "Bank Transfer"
        case qris = "QRIS"
    }
    
    // Dummy payment details
    private let bankAccount = BankAccount(
        bank: .mandiri,
        accountNumber: "1234567890",
        accountHolder: "PT. DECREME INDONESIA"
    )
    
    var body: some View {
        NavigationView {
            Form {
                // Amount Section
                Section {
                    Text("Amount to Pay")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatPrice(total))
                        .font(.headline)
                }
                
                // Payment Method Section
                Section {
                    Picker("Payment Method", selection: $selectedMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Payment Details based on selected method
                    switch selectedMethod {
                    case .cash:
                        CashPaymentView()
                    case .transfer:
                        BankTransferDetailView(bankAccount: bankAccount)
                    case .qris:
                        QRISDetailView(total: total)
                    }
                }
                
                // Invoice Section
                Section {
                    Button(action: generateAndPreviewInvoice) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("View Invoice")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
//                    .foregroundColor(.blue)
                }
                
                // Complete Payment Section
                Section {
                    Button(action: completePayment) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Complete Payment")
                            Spacer()
                            Text(formatPrice(total))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPDFPreview) {
                if let pdf = invoicePDF {
                    PDFPreviewView(pdfData: pdf)
                }
            }
            .alert("Thank You!", isPresented: $showingThankYouAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Thank you for your order!")
            }
        }
    }
    
    private func generateAndPreviewInvoice() {
        Task {
            do {
                invoicePDF = try await InvoiceGenerator.generateInvoice(
                    orderNumber: orderNumber,
                    client: client,
                    items: items,
                    subtotal: subtotal,
                    deliveryFee: deliveryFee,
                    ppn: ppn,
                    total: total,
                    paymentMethod: selectedMethod.rawValue,
                    buyerName: buyerName,
                    buyerPhone: buyerPhone,
                    notes: notes,
                    isPersonalBuyer: client.isPersonal
                )
                
                if let pdf = invoicePDF {
                    print("PDF generated successfully, size: \(pdf.count) bytes")
                    showingPDFPreview = true
                } else {
                    print("Failed to generate PDF")
                }
            } catch {
                print("Error generating PDF: \(error)")
            }
        }
    }
    
    private func completePayment() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let order = try await SupabaseService.shared.createOrder(
                    orderNumber: orderNumber,
                    clientId: client.id,
                    items: items,
                    deliveryFee: deliveryFee,
                    ppn: ppn,
                    totalAmount: total,
                    buyerName: buyerName,
                    buyerPhone: buyerPhone,
                    notes: notes.isEmpty ? "" : notes
                )
                
                try await SupabaseService.shared.updateOrderStatus(orderId: order.id, status: "confirmed")
                
                // Clear cart and show thank you alert
                onClearCart()
                showingThankYouAlert = true
                
                // Complete payment after alert is dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onPaymentComplete(selectedMethod.rawValue)
                }
            } catch {
                self.error = error
            }
        }
    }
}

// Bank enum and model
enum Bank: String {
    case bca = "BCA"
    case bni = "BNI"
    case mandiri = "Mandiri"
    
    var logoName: String {
        "logo-\(rawValue.lowercased())"
    }
}

struct BankAccount {
    let bank: Bank
    let accountNumber: String
    let accountHolder: String
    
    var bankName: String { bank.rawValue }
    var logoName: String { bank.logoName }
}

// Cash Payment View
struct CashPaymentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pay with Cash")
                .font(.headline)
            Text("Please prepare the exact amount")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// Bank Transfer Detail View
struct BankTransferDetailView: View {
    let bankAccount: BankAccount
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(bankAccount.logoName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
                    .background(Color.white)
                    .cornerRadius(4)
                
                Text(bankAccount.bankName)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Account Number:")
                        .foregroundColor(.secondary)
                    Text(bankAccount.accountNumber)
                        .bold()
                    Spacer()
                    Button {
                        UIPasteboard.general.string = bankAccount.accountNumber
                        withAnimation {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isCopied = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isCopied ? "Copied!" : "Copy")
                                .font(.caption)
                            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        }
                        .foregroundColor(isCopied ? .green : .blue)
                    }
                }
                
                Text("Account Name:")
                    .foregroundColor(.secondary)
                Text(bankAccount.accountHolder)
                    .bold()
            }
        }
        .padding(.vertical, 8)
    }
}

// QRIS Detail View
struct QRISDetailView: View {
    let total: Decimal
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "qrcode")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            Text("Scan with any QRIS-supported payment app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary URL for the PDF data
        if let pdfData = items.first as? Data {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("invoice.pdf")
            // debug PDF location
            print("Printed PDF location: \(tempURL)")
            do {
                try pdfData.write(to: tempURL)
                let activityVC = UIActivityViewController(
                    activityItems: [tempURL],
                    applicationActivities: nil
                )
                return activityVC
            } catch {
                print("Error writing PDF to temp file: \(error)") // Debug print
            }
        }
        
        // Fallback if PDF data handling fails
        return UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
