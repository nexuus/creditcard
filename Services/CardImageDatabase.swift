//
//  CardImageDatabase.swift
//  CreditCardTracker
//

import SwiftUI
import Foundation

/// A database for mapping credit cards to their images
class CardImageDatabase {
    // Singleton instance
    static let shared = CardImageDatabase()
    
    // Thread-safe queue for database operations
    private let databaseQueue = DispatchQueue(label: "com.creditcardtracker.CardImageDatabase", attributes: .concurrent)
    
    private let baseImageURL = "https://www.offeroptimist.com"
    
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
    struct CardImageInfo: Codable {
        let cardId: String
        let issuer: String
        let cardName: String
        let imageURL: String
        var localPath: String?
        var lastUpdated: Date
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
        databaseQueue.sync {
            if cardImageMap.isEmpty {
                initializeDefaultMappings()
            }
        }
        
        isInitialized = true
    }
    
    /// Get image for a specific card
    func getImageForCard(cardId: String, card: CreditCardInfo?) async -> UIImage? {
        // Ensure database is initialized
        if !isInitialized {
            await initialize()
        }
        
        // Check if we have this card in our database (thread-safe read)
        var imageInfo: CardImageInfo?
        databaseQueue.sync {
            imageInfo = cardImageMap[cardId]
        }
        
        if let imageInfo = imageInfo, !imageInfo.imageURL.isEmpty {
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
                    // Update the database entry (thread-safe)
                    databaseQueue.async(flags: .barrier) {
                        var updatedInfo = imageInfo
                        updatedInfo.localPath = localPath
                        self.cardImageMap[cardId] = updatedInfo
                        self.saveDatabase()
                    }
                }
                return image
            }
        }
        
        // Only proceed if we have a valid card object
        guard let card = card else {
            print("⚠️ No card info provided for ID: \(cardId)")
            return nil
        }
        
        // Otherwise, try to find by card name and issuer
        let searchKey = "\(card.issuer.lowercased())-\(card.name.lowercased())"
        
        var matchedCardInfo: CardImageInfo?
        var matchedCardInfoURL: String?
        
        // Thread-safe read
        databaseQueue.sync {
            for (_, info) in cardImageMap where
                "\(info.issuer.lowercased())-\(info.cardName.lowercased())".contains(searchKey) {
                matchedCardInfo = info
                matchedCardInfoURL = info.imageURL
                break
            }
        }
        
        // If we found a match, try to load the image
        if let matchedInfo = matchedCardInfo, let imageURL = matchedCardInfoURL {
            // If we have a local path, load from there
            if let localPath = matchedInfo.localPath, !localPath.isEmpty {
                if let localImage = loadImageFromLocalPath(localPath) {
                    // Update the mapping with this card ID for future lookups (thread-safe)
                    databaseQueue.async(flags: .barrier) {
                        self.cardImageMap[cardId] = CardImageInfo(
                            cardId: cardId,
                            issuer: card.issuer,
                            cardName: card.name,
                            imageURL: imageURL,
                            localPath: localPath,
                            lastUpdated: Date(),
                            source: "matched"
                        )
                        self.saveDatabase()
                    }
                    return localImage
                }
            }
            
            // Try to download from the URL
            if let image = await downloadImage(from: imageURL) {
                // Save the image to local storage for next time
                if let localPath = saveImageToLocalStorage(image, cardId: cardId) {
                    // Update the database entry (thread-safe)
                    databaseQueue.async(flags: .barrier) {
                        self.cardImageMap[cardId] = CardImageInfo(
                            cardId: cardId,
                            issuer: card.issuer,
                            cardName: card.name,
                            imageURL: imageURL,
                            localPath: localPath,
                            lastUpdated: Date(),
                            source: "matched"
                        )
                        self.saveDatabase()
                    }
                    return image
                }
            }
        }
        
        // If we couldn't find an image, add to database with empty URL
        // This avoids repeated searches for the same card (thread-safe)
        databaseQueue.async(flags: .barrier) {
            if self.cardImageMap[cardId] == nil {
                self.cardImageMap[cardId] = CardImageInfo(
                    cardId: cardId,
                    issuer: card.issuer,
                    cardName: card.name,
                    imageURL: "",
                    localPath: nil,
                    lastUpdated: Date(),
                    source: "pending"
                )
                self.saveDatabase()
            }
        }
        
        return nil
    }
    
    /// Add or update an image mapping
    func addImageMapping(cardId: String, issuer: String, cardName: String, imageURL: String) {
        databaseQueue.async(flags: .barrier) {
            self.cardImageMap[cardId] = CardImageInfo(
                cardId: cardId,
                issuer: issuer,
                cardName: cardName,
                imageURL: imageURL,
                localPath: nil,
                lastUpdated: Date(),
                source: "manual"
            )
            self.saveDatabase()
        }
    }
    
    /// Add an image from API
    func addImageFromAPI(cardId: String, issuer: String, cardName: String, imageURL: String) {
        databaseQueue.async(flags: .barrier) {
            // Only add if we don't already have a manual entry
            if let existing = self.cardImageMap[cardId], existing.source == "manual" {
                return
            }
            
            self.cardImageMap[cardId] = CardImageInfo(
                cardId: cardId,
                issuer: issuer,
                cardName: cardName,
                imageURL: imageURL,
                localPath: nil,
                lastUpdated: Date(),
                source: "api"
            )
            self.saveDatabase()
        }
    }
    
    /// Clear the database
    func clearDatabase() {
        databaseQueue.async(flags: .barrier) {
            self.cardImageMap.removeAll()
            self.saveDatabase()
            self.isInitialized = false
        }
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
                
                // Thread-safe write
                let decodedMap = try decoder.decode([String: CardImageInfo].self, from: data)
                databaseQueue.async(flags: .barrier) {
                    self.cardImageMap = decodedMap
                }
                print("✅ Loaded card image database with \(decodedMap.count) entries")
            } else {
                print("ℹ️ No existing card image database found, creating new one")
                databaseQueue.async(flags: .barrier) {
                    self.cardImageMap = [:]
                }
            }
        } catch {
            print("❌ Failed to load card image database: \(error)")
            databaseQueue.async(flags: .barrier) {
                self.cardImageMap = [:]
            }
        }
    }
    
    /// Save the database to disk
    private func saveDatabase() {
        guard let databaseURL = databaseURL else {
            print("❌ Could not determine database URL")
            return
        }
        
        // Create a local copy to avoid holding the lock during file I/O
        // Fix: Initialize the variable immediately
        let imagesToSave: [String: CardImageInfo] = databaseQueue.sync {
            return self.cardImageMap
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(imagesToSave)
            try data.write(to: databaseURL)
            print("✅ Saved card image database with \(imagesToSave.count) entries")
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
    /// Download an image from a URL
    private func downloadImage(from urlString: String) async -> UIImage? {
        guard !urlString.isEmpty else {
            print("❌ Empty image URL")
            return nil
        }
        
        // Handle relative URLs by prepending base URL if needed
        let finalURLString: String
        if urlString.hasPrefix("/") {
            finalURLString = baseImageURL + urlString
        } else {
            finalURLString = urlString
        }
        
        guard let url = URL(string: finalURLString) else {
            print("❌ Invalid image URL: \(finalURLString)")
            return nil
        }
        
        print("🌐 Attempting to download image from: \(finalURLString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response downloading image")
                return nil
            }
            
            print("📥 Image download response status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode) downloading image")
                return nil
            }
            
            if let image = UIImage(data: data) {
                print("✅ Successfully downloaded image from \(finalURLString)")
                return image
            } else {
                print("❌ Invalid image data from \(finalURLString)")
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
