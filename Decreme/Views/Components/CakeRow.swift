import SwiftUI

struct CakeRow: View {
    let cake: Cake
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Cake image
                if let images = cake.images, let url = URL(string: images) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                }
                
                // Cake details
                VStack(alignment: .leading, spacing: 4) {
                    Text(cake.name)
                        .font(.headline)
                    Text(cake.variant)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatPrice(cake.price))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Availability indicator
                if let isAvailable = cake.isAvailable {
                    Circle()
                        .fill(isAvailable ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .foregroundColor(.primary)
    }
} 