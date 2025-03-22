//
//  CardImageDatabase.swift
//  CreditCardTracker
//
//  Created by Hassan  on 3/18/25.
//

// Add this as a new file: Services/CardImageDatabase.swift

import SwiftUI
import Foundation

/// A database for mapping credit cards to their images
class CardImageDatabase {
    // Singleton instance
    static let shared = CardImageDatabase()
    
    // Path to the local database file
    private let databaseURL: URL? = {
        let fileManager = FileManager.default
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDir.appendingPathComponent("card_image_mapping.json")
    }()
    
    // Path to image storage directory
    private let imageDirectoryURL: URL? = {
        let fileManager = FileManager.default
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDir.appendingPathComponent("card_images")
    }()
    
    // The in-memory mapping of card IDs to image information
    private var cardImageMap: [String: CardImageInfo] = [:]
    
    // Has the database been initialized
    private var isInitialized = false
    
    // Private initializer for singleton
    private init() {}
    
    // MARK: - Database Structures
    
    /// Structure to store card image information
    /// Structure to store card image information - with mutable properties
    struct CardImageInfo: Codable {
        let cardId: String
        let issuer: String
        let cardName: String
        let imageURL: String
        var localPath: String?  // Changed to var so it can be updated
        var lastUpdated: Date   // Changed to var so it can be updated
        let source: String      // "api", "manual", "generated"
    }
    
    // MARK: - Public Methods
    
    /// Initialize the database
    func initialize() async {
        guard !isInitialized else { return }
        
        // Create directory for images if needed
        if let directory = imageDirectoryURL {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                print("✅ Created card image directory at: \(directory.path)")
            } catch {
                print("❌ Failed to create card image directory: \(error)")
            }
        }
        
        // Load the database
        await loadDatabase()
        
        // Initialize with default mappings if empty
        if cardImageMap.isEmpty {
            initializeDefaultMappings()
        }
        
        isInitialized = true
    }
    
    /// Get image for a specific card
    func getImageForCard(cardId: String, card: CreditCardInfo) async -> UIImage? {
        // Ensure database is initialized
        if !isInitialized {
            await initialize()
        }
        
        // Check if we have this card in our database
        if let imageInfo = cardImageMap[cardId], !imageInfo.imageURL.isEmpty {
            // If we have a local path, load from there
            if let localPath = imageInfo.localPath, !localPath.isEmpty {
                if let localImage = loadImageFromLocalPath(localPath) {
                    return localImage
                }
            }
            
            // Try to download from the URL
            if let image = await downloadImage(from: imageInfo.imageURL) {
                // Save the image to local storage for next time
                if let localPath = saveImageToLocalStorage(image, cardId: cardId) {
                    // Update the database entry
                    var updatedInfo = imageInfo
                    updatedInfo.localPath = localPath
                    cardImageMap[cardId] = updatedInfo
                    saveDatabase()
                }
                return image
            }
        }
        
        // Otherwise, try to find by card name and issuer
        let searchKey = "\(card.issuer.lowercased())-\(card.name.lowercased())"
        for (_, imageInfo) in cardImageMap where
            "\(imageInfo.issuer.lowercased())-\(imageInfo.cardName.lowercased())".contains(searchKey) {
            
            // If we have a local path, load from there
            if let localPath = imageInfo.localPath, !localPath.isEmpty {
                if let localImage = loadImageFromLocalPath(localPath) {
                    // Update the mapping with this card ID for future lookups
                    cardImageMap[cardId] = CardImageInfo(
                        cardId: cardId,
                        issuer: card.issuer,
                        cardName: card.name,
                        imageURL: imageInfo.imageURL,
                        localPath: localPath,
                        lastUpdated: Date(),
                        source: "matched"
                    )
                    saveDatabase()
                    return localImage
                }
            }
            
            // Try to download from the URL
            if let image = await downloadImage(from: imageInfo.imageURL) {
                // Save the image to local storage for next time
                if let localPath = saveImageToLocalStorage(image, cardId: cardId) {
                    // Update the database entry
                    cardImageMap[cardId] = CardImageInfo(
                        cardId: cardId,
                        issuer: card.issuer,
                        cardName: card.name,
                        imageURL: imageInfo.imageURL,
                        localPath: localPath,
                        lastUpdated: Date(),
                        source: "matched"
                    )
                    saveDatabase()
                    return image
                }
            }
        }
        
        // If we couldn't find an image, add to database with empty URL
        // This avoids repeated searches for the same card
        if cardImageMap[cardId] == nil {
            cardImageMap[cardId] = CardImageInfo(
                cardId: cardId,
                issuer: card.issuer,
                cardName: card.name,
                imageURL: "",
                localPath: nil,
                lastUpdated: Date(),
                source: "pending"
            )
            saveDatabase()
        }
        
        return nil
    }
    
    /// Add or update an image mapping
    func addImageMapping(cardId: String, issuer: String, cardName: String, imageURL: String) {
        cardImageMap[cardId] = CardImageInfo(
            cardId: cardId,
            issuer: issuer,
            cardName: cardName,
            imageURL: imageURL,
            localPath: nil,
            lastUpdated: Date(),
            source: "manual"
        )
        saveDatabase()
    }
    
    /// Add an image from API
    func addImageFromAPI(cardId: String, issuer: String, cardName: String, imageURL: String) {
        // Only add if we don't already have a manual entry
        if let existing = cardImageMap[cardId], existing.source == "manual" {
            return
        }
        
        cardImageMap[cardId] = CardImageInfo(
            cardId: cardId,
            issuer: issuer,
            cardName: cardName,
            imageURL: imageURL,
            localPath: nil,
            lastUpdated: Date(),
            source: "api"
        )
        saveDatabase()
    }
    
    /// Clear the database
    func clearDatabase() {
        cardImageMap.removeAll()
        saveDatabase()
        isInitialized = false
    }
    
    // MARK: - Private Methods
    
    /// Load the database from disk
    private func loadDatabase() async {
        guard let databaseURL = databaseURL else {
            print("❌ Could not determine database URL")
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: databaseURL.path) {
                let data = try Data(contentsOf: databaseURL)
                let decoder = JSONDecoder()
                cardImageMap = try decoder.decode([String: CardImageInfo].self, from: data)
                print("✅ Loaded card image database with \(cardImageMap.count) entries")
            } else {
                print("ℹ️ No existing card image database found, creating new one")
                cardImageMap = [:]
            }
        } catch {
            print("❌ Failed to load card image database: \(error)")
            cardImageMap = [:]
        }
    }
    
    /// Save the database to disk
    private func saveDatabase() {
        guard let databaseURL = databaseURL else {
            print("❌ Could not determine database URL")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cardImageMap)
            try data.write(to: databaseURL)
            print("✅ Saved card image database with \(cardImageMap.count) entries")
        } catch {
            print("❌ Failed to save card image database: \(error)")
        }
    }
    
    /// Initialize with default mappings for common cards
    private func initializeDefaultMappings() {
        // These URLs are examples - replace with actual card image URLs
        let defaultMappings: [(id: String, issuer: String, name: String, url: String)] = [
            ("chase-sapphire-preferred", "Chase", "Sapphire Preferred", "https://creditcards.chase.com/sites/default/files/images/cards/card_legacy_csp.png"),
            ("chase-sapphire-reserve", "Chase", "Sapphire Reserve", "https://creditcards.chase.com/sites/default/files/images/cards/card_legacy_csr.png"),
            ("amex-gold", "American Express", "Gold Card", "https://www.nerdwallet.com/cdn-cgi/image/width=1800,quality=85/cdn/images/marketplace/credit_cards/cc-amex-gold-nw-image.png"),
            ("amex-platinum", "American Express", "Platinum Card", "https://www.nerdwallet.com/cdn-cgi/image/width=1800,quality=85/cdn/images/marketplace/credit_cards/cc-amex-platinum-nw-image.png"),
            ("chase-freedom-unlimited", "Chase", "Freedom Unlimited", "https://creditcards.chase.com/sites/default/files/images/cards/card_legacy_cfu.png"),
            ("capital-one-venture", "Capital One", "Venture", "https://www.nerdwallet.com/cdn-cgi/image/width=1800,quality=85/cdn/images/marketplace/credit_cards/60b02e2116a0e4d1b3e9fc44/cc-cap1-venture-rewards-nw-image.png"),
            ("discover-it", "Discover", "Discover it", "https://www.nerdwallet.com/cdn-cgi/image/width=1800,quality=85/cdn/images/marketplace/credit_cards/cc-discover-it-cash-back-nw-image.png"),
            ("citi-double-cash", "Citi", "Double Cash", "https://www.nerdwallet.com/cdn-cgi/image/width=1800,quality=85/cdn/images/marketplace/credit_cards/cc-citi-double-cash-nw-image.png")
        ]
        
        for mapping in defaultMappings {
            cardImageMap[mapping.id] = CardImageInfo(
                cardId: mapping.id,
                issuer: mapping.issuer,
                cardName: mapping.name,
                imageURL: mapping.url,
                localPath: nil,
                lastUpdated: Date(),
                source: "default"
            )
        }
        
        saveDatabase()
    }
    
    /// Download an image from a URL
    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid image URL: \(urlString)")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ Invalid response downloading image from \(urlString)")
                return nil
            }
            
            if let image = UIImage(data: data) {
                print("✅ Successfully downloaded image from \(urlString)")
                return image
            } else {
                print("❌ Invalid image data from \(urlString)")
                return nil
            }
        } catch {
            print("❌ Error downloading image: \(error)")
            return nil
        }
    }
    
    /// Save image to local storage
    private func saveImageToLocalStorage(_ image: UIImage, cardId: String) -> String? {
        guard let directory = imageDirectoryURL else {
            print("❌ Could not determine image directory URL")
            return nil
        }
        
        // Create a safe filename
        let safeCardId = cardId.replacingOccurrences(of: "/", with: "_")
                               .replacingOccurrences(of: ":", with: "_")
                               .replacingOccurrences(of: "?", with: "_")
                               .replacingOccurrences(of: "&", with: "_")
                               .replacingOccurrences(of: "=", with: "_")
        
        let filename = "\(safeCardId).png"
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            if let pngData = image.pngData() {
                try pngData.write(to: fileURL)
                print("✅ Saved image for \(cardId) to \(fileURL.path)")
                return filename
            }
            return nil
        } catch {
            print("❌ Failed to save image to local storage: \(error)")
            return nil
        }
    }
    
    /// Load image from local path
    private func loadImageFromLocalPath(_ localPath: String) -> UIImage? {
        guard let directory = imageDirectoryURL else {
            print("❌ Could not determine image directory URL")
            return nil
        }
        
        let fileURL = directory.appendingPathComponent(localPath)
        
        do {
            let data = try Data(contentsOf: fileURL)
            if let image = UIImage(data: data) {
                return image
            }
            return nil
        } catch {
            print("❌ Failed to load image from local storage: \(error)")
            return nil
        }
    }
}
