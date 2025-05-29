import SwiftUI

struct OrderDetailView: View {
    // MARK: - Properties
    let initialOrder: Order // Non-state property for initialization
    @State private var currentOrder: Order
    @State private var orderItemsWithCakes: [(OrderItem, Cake?)] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var isUpdatingStatus = false
    @State private var selectedStatus: OrderStatus
    @State private var showStatusUpdateAlert = false
    @State private var statusUpdateError: Error?
    
    // MARK: - Initialization
    init(order: Order) {
        self.initialOrder = order
        self._currentOrder = State(initialValue: order)
        self._selectedStatus = State(initialValue: OrderStatus(rawValue: order.status.lowercased()) ?? .pending)
    }
    
    // MARK: - Subviews
    private var orderInformationSection: some View {
        Section("Order Information") {
            OrderInfoRow(title: "Order Number", value: currentOrder.orderNumber)
            OrderInfoRow(title: "Date", value: currentOrder.createdAt.formatted())
            
            HStack {
                Text("Current Status")
                Spacer()
                StatusBadge(status: currentOrder.status)
            }
            
            StatusUpdateView(
                selectedStatus: $selectedStatus,
                currentStatus: currentOrder.status,
                isUpdatingStatus: isUpdatingStatus,
                onUpdate: updateOrderStatus
            )
        }
    }
    
    private var itemsSection: some View {
        Section {
            itemsContent
        } header: {
            Text("Items")
        }
    }

    @ViewBuilder
    private var itemsContent: some View {
        if isLoading {
            loadingView
        } else if orderItemsWithCakes.isEmpty {
            emptyView
        } else {
            itemsListView
        }
    }

    private var loadingView: some View {
        Text("Loading...")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        Text("No items found")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var itemsListView: some View {
        ForEach(orderItemsWithCakes, id: \.0.id) { item, cake in
            OrderItemRow(item: item, cake: cake)
        }
    }
    
    private var paymentSection: some View {
        Section("Payment Details") {
            PaymentRow(title: "Subtotal", amount: currentOrder.totalAmount - currentOrder.ppn - currentOrder.deliveryFee)
            PaymentRow(title: "PPN (10%)", amount: currentOrder.ppn)
            PaymentRow(title: "Delivery Fee", amount: currentOrder.deliveryFee)
            PaymentRow(title: "Total", amount: currentOrder.totalAmount, isBold: true)
        }
    }
    
    // MARK: - Body
    var body: some View {
        List {
            orderInformationSection
            itemsSection
            paymentSection
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadOrderItemsWithCakes()
        }
        .alert("Error", isPresented: .constant(error != nil), presenting: error) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Status Update Error", isPresented: .constant(statusUpdateError != nil), presenting: statusUpdateError) { _ in
            Button("OK", role: .cancel) { statusUpdateError = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Status Updated", isPresented: $showStatusUpdateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Order status has been successfully updated.")
        }
    }
    
    // MARK: - Methods
    private func updateOrderStatus() async {
        isUpdatingStatus = true
        defer { isUpdatingStatus = false }
        
        do {
            print("Updating order status - Order ID: \(currentOrder.id), New Status: \(selectedStatus.rawValue)")
            
            try await SupabaseService.shared.updateOrderStatus(orderId: currentOrder.id, status: selectedStatus.rawValue)
            print("Status update request successful")
            
            if let updatedOrder = try await SupabaseService.shared.fetchOrder(id: currentOrder.id) {
                print("Fetched updated order - Old Status: \(currentOrder.status), New Status: \(updatedOrder.status)")
                
                // Update both the current order and selected status
                currentOrder = updatedOrder
                selectedStatus = OrderStatus(rawValue: updatedOrder.status.lowercased()) ?? .pending
                showStatusUpdateAlert = true
            } else {
                print("Error: Could not fetch updated order")
                statusUpdateError = NSError(domain: "", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Could not fetch updated order"])
            }
        } catch {
            print("Error updating status: \(error.localizedDescription)")
            statusUpdateError = error
        }
    }
    
    private func loadOrderItemsWithCakes() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let items = try await SupabaseService.shared.fetchOrderItems(orderId: currentOrder.id)
            orderItemsWithCakes = []
            
            for item in items {
                do {
                    let cake = try await SupabaseService.shared.fetchCake(id: item.cakeId)
                    orderItemsWithCakes.append((item, cake))
                } catch {
                    print("Error fetching cake \(item.cakeId): \(error)")
                    orderItemsWithCakes.append((item, nil))
                }
            }
        } catch {
            self.error = error
        }
    }
}

// MARK: - Supporting Views
struct OrderInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct OrderItemRow: View {
    let item: OrderItem
    let cake: Cake?
    
    var body: some View {
        HStack {
            if let cake = cake {
                Text("\(cake.name) - \(cake.variant)")
            } else {
                Text("Unknown Cake")
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(item.quantity)x")
                .foregroundColor(.secondary)
            Text(formatPrice(item.price))
        }
    }
}

struct PaymentRow: View {
    let title: String
    let amount: Decimal
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(isBold ? .bold : .regular)
            Spacer()
            Text(formatPrice(amount))
                .fontWeight(isBold ? .bold : .regular)
        }
    }
}

struct StatusBadge: View {
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

struct StatusUpdateView: View {
    @Binding var selectedStatus: OrderStatus
    let currentStatus: String
    let isUpdatingStatus: Bool
    let onUpdate: () async -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Change Status")
                Spacer()
                Picker("Status", selection: $selectedStatus) {
                    ForEach(OrderStatus.allCases, id: \.self) { status in
                        Text(status.displayName)
                            .tag(status)
                    }
                }
                .disabled(isUpdatingStatus)
            }
            
            if selectedStatus.rawValue != currentStatus.lowercased() {
                Button(action: {
                    Task {
                        await onUpdate()
                    }
                }) {
                    HStack {
                        Text("Update Status")
                        if isUpdatingStatus {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isUpdatingStatus)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 4)
            }
        }
    }
} 
