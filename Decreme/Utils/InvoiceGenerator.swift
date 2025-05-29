//
//  InvoiceGenerator.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 27/12/24.
//

import Foundation
import PDFKit
import UIKit

class InvoiceGenerator {
    static func generateInvoice(
        orderNumber: String,
        client: Client,
        items: [CartItem],
        subtotal: Decimal,
        deliveryFee: Decimal,
        ppn: Decimal,
        total: Decimal,
        paymentMethod: String,
        buyerName: String,
        buyerPhone: String,
        notes: String?,
        isPersonalBuyer: Bool
    ) async throws -> Data? {
        print("Starting invoice generation...")
        
        // Fetch settings
        let storeLogo = try await SupabaseService.shared.fetchStoreLogo()
        let bankAccount = try await SupabaseService.shared.fetchBankAccount()
        let bankAccountName = try await SupabaseService.shared.fetchBankName()
        let bankInvoice = try await SupabaseService.shared.fetchBankInvoice()
        
        // PDF setup
        let pdfMetaData = [
            kCGPDFContextCreator: "Decreme App",
            kCGPDFContextAuthor: "Decreme"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Margins and spacing
        let margin: CGFloat = 40.0
        let contentWidth = pageWidth - (margin * 2)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Logo dimensions
            let logoHeight: CGFloat = 100.0
            let logoWidth: CGFloat = 100.0
            let topMargin: CGFloat = 30.0
            
            // Draw Decreme logo on the left
            if let storeLogoUrl = URL(string: storeLogo ?? ""),
               let storeLogoData = try? Data(contentsOf: storeLogoUrl),
               let storeLogo = UIImage(data: storeLogoData) {
                let leftLogoRect = CGRect(x: margin, y: topMargin, width: logoWidth, height: logoHeight)
                storeLogo.draw(in: leftLogoRect)
            }
            
            // Draw client logo on the right
            if let clientLogoUrl = URL(string: client.logo ?? ""),
               let clientLogoData = try? Data(contentsOf: clientLogoUrl),
               let clientLogo = UIImage(data: clientLogoData) {
                let rightLogoRect = CGRect(x: pageWidth - margin - logoWidth, y: topMargin, width: logoWidth, height: logoHeight)
                clientLogo.draw(in: rightLogoRect)
            }
            
            let regularFont = UIFont.systemFont(ofSize: 12.0)
            let boldFont = UIFont.boldSystemFont(ofSize: 12.0)
            
            // Start content below logos
            var currentY: CGFloat = topMargin + logoHeight + 20
            
            // Invoice details
            let detailsLabel = isPersonalBuyer ? "Customer:" : "Store Details:"
            let invoiceDetails = """
            Invoice Number: \(orderNumber)
            Date: \(Date().formatted())
            
            \(detailsLabel)
            \(isPersonalBuyer ? buyerName : client.name)
            \(isPersonalBuyer ? "Phone: \(buyerPhone)" : client.address)
            \(isPersonalBuyer ? "" : client.city)
            """
            
            let detailsAttributes = [NSAttributedString.Key.font: regularFont]
            invoiceDetails.draw(at: CGPoint(x: margin, y: currentY), withAttributes: detailsAttributes)
            
            currentY += 130
            
            // Items table
            let colWidths: [CGFloat] = [0.4, 0.2, 0.2, 0.2] // Proportions of contentWidth
            var colX: [CGFloat] = []
            var currentX = margin
            
            for width in colWidths {
                colX.append(currentX)
                currentX += contentWidth * width
            }
            
            let headers = ["Item", "Qty", "Price", "Total"]
            let headerAttributes = [NSAttributedString.Key.font: boldFont]
            
            // Draw headers
            for (index, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: colX[index], y: currentY), withAttributes: headerAttributes)
            }
            
            currentY += 20
            
            // Draw items
            let itemAttributes = [NSAttributedString.Key.font: regularFont]
            for item in items {
                let itemTotal = item.price * Decimal(item.quantity)
                let itemFullname = item.cake.name + " " + item.cake.variant
                
                itemFullname.draw(at: CGPoint(x: colX[0], y: currentY), withAttributes: itemAttributes)
                "\(item.quantity)".draw(at: CGPoint(x: colX[1], y: currentY), withAttributes: itemAttributes)
                formatPrice(item.price).draw(at: CGPoint(x: colX[2], y: currentY), withAttributes: itemAttributes)
                formatPrice(itemTotal).draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: itemAttributes)
                
                currentY += 20
            }
            
            currentY += 20
            
            // Notes section
            if let notes = notes, !notes.isEmpty {
                let notesTitle = "Notes:"
                notesTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
                currentY += 20
                notes.draw(at: CGPoint(x: margin, y: currentY), withAttributes: itemAttributes)
                currentY += 40
            }
            
            // Summary section (right-aligned)
            let summaryItems = [
                ("Subtotal:", subtotal),
                ("Delivery Fee:", deliveryFee),
                ("PPN (10%):", ppn),
                ("Total:", total)
            ]
            
            let summaryX = pageWidth - margin - contentWidth * 0.4 // Align with last column
            for (label, amount) in summaryItems {
                label.draw(at: CGPoint(x: summaryX, y: currentY), withAttributes: headerAttributes)
                formatPrice(amount).draw(at: CGPoint(x: colX[3], y: currentY), withAttributes: itemAttributes)
                currentY += 20
            }
            
            currentY += 30
            
            // Bank information section
            let bankIcon = "🏦"
            let transferLabel = "\(bankIcon) Transfer to:"
            transferLabel.draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
            currentY += 25
            
            let bankInfo = [
                "Bank: \(bankInvoice ?? "BCA")",
                "Name: \(bankAccountName ?? "PT. DECREME INDONESIA")",
                "Account No: \(bankAccount ?? "1234567890")"
            ]
            
            for info in bankInfo {
                info.draw(at: CGPoint(x: margin, y: currentY), withAttributes: itemAttributes)
                currentY += 20
            }
            
            // Footer
            let footer = "Thank you for your order!"
            footer.draw(at: CGPoint(x: margin, y: pageHeight - 50), withAttributes: itemAttributes)
        }
        
        return data
    }
}
