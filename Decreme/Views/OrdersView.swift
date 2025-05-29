//
//  OrdersView.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import SwiftUI

struct OrdersView: View {
    @State private var orders: [Order] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedStatus: OrderStatus? = nil
    
    var filteredOrders: [Order] {
        guard let status = selectedStatus else {
            return orders
        }
        return orders.filter { $0.status == status.rawValue }
    }
    
    // Count orders by status
    private func orderCount(for status: OrderStatus?) -> Int {
        if status == nil {
            return orders.count
        }
        return orders.filter { $0.status == status?.rawValue }.count
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Status Filter with counts
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All (\(orderCount(for: nil)))",
                                isSelected: selectedStatus == nil,
                                action: { selectedStatus = nil }
                            )
                            
                            ForEach(OrderStatus.allCases, id: \.self) { status in
                                FilterChip(
                                    title: "\(status.displayName) (\(orderCount(for: status)))",
                                    isSelected: selectedStatus == status,
                                    action: { selectedStatus = status }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    if isLoading {
                        ProgressView()
                    } else if filteredOrders.isEmpty {
                        EmptyOrdersView(selectedStatus: selectedStatus)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredOrders.enumerated()), id: \.element.id) { index, order in
                                NavigationLink(destination: OrderDetailView(order: order)) {
                                    VStack(spacing: 0) {
                                        HStack {
                                            Text("\(index + 1)")
                                                .foregroundColor(.secondary)
                                                .frame(width: 30, alignment: .center)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(order.orderNumber)
                                                    .font(.system(.body, design: .monospaced))
                                                Text(formatDate(order.createdAt))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text(formatPrice(order.totalAmount))
                                                    .fontWeight(.semibold)
                                                OrderStatusBadge(status: order.status)
                                            }
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 12)
                                        
                                        if index < filteredOrders.count - 1 {
                                            Divider()
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Orders")
            .refreshable {
                await loadOrders()
            }
        }
        .task {
            await loadOrders()
        }
    }
    
    private func loadOrders() async {
        isLoading = true
        do {
            orders = try await SupabaseService.shared.fetchOrders()
        } catch {
            self.error = error
            print("Error loading orders:", error)
        }
        isLoading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

struct OrderRow: View {
    let order: Order
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.orderNumber)
                    .font(.system(.body, design: .monospaced))
                Text(formatDate(order.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatPrice(order.totalAmount))
                    .fontWeight(.semibold)
                OrderStatusBadge(status: order.status)
            }
        }
    }
    
    // Date formatter function
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

struct OrderStatusBadge: View {
    let status: String
    
    private var backgroundColor: Color {
        switch status.lowercased() {
        case "pending":
            return Color.orange.opacity(0.2)
        case "confirmed":
            return Color.blue.opacity(0.2)
        case "preparing":
            return Color.yellow.opacity(0.2)
        case "ready":
            return Color.green.opacity(0.2)
        case "completed":
            return Color.gray.opacity(0.2)
        case "cancelled":
            return Color.red.opacity(0.2)
        case "paid":
            return Color.green.opacity(0.2)
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch status.lowercased() {
        case "pending":
            return .orange
        case "confirmed":
            return .blue
        case "preparing":
            return .yellow
        case "ready":
            return .green
        case "completed":
            return .gray
        case "cancelled":
            return .red
        case "paid":
            return .green
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(6)
    }
}

// Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// Empty State View
struct EmptyOrdersView: View {
    let selectedStatus: OrderStatus?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(selectedStatus == nil ? "No orders yet" : "No \(selectedStatus?.displayName.lowercased() ?? "") orders")
                .font(.headline)
            
            Text("Orders will appear here once created")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
