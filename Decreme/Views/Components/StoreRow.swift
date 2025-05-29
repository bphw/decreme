import SwiftUI

struct StoreRow: View {
    let store: Client
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Store logo
                if let logo = store.logo {
                    AsyncImage(url: URL(string: logo)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                }
                
                // Store details
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.headline)
                    Text(store.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(store.phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Store type indicator
                if store.isPersonal {
                    Text("Personal")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .foregroundColor(.primary)
    }
} 