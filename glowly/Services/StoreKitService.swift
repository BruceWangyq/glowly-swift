//
//  StoreKitService.swift
//  Glowly
//
//  StoreKit integration for managing subscriptions and in-app purchases
//

import Foundation
import StoreKit
import Combine

protocol StoreKitServiceProtocol: ObservableObject {
    var products: [Product] { get }
    var subscriptionStatus: SubscriptionStatus { get }
    var purchaseState: PurchaseState { get }
    var isLoading: Bool { get }
    
    func loadProducts() async throws
    func purchase(_ product: Product) async throws -> PurchaseResult
    func restorePurchases() async throws
    func validateReceipt() async throws -> SubscriptionStatus
    func checkSubscriptionStatus() async -> SubscriptionStatus
}

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case succeeded(Product)
    case failed(Error)
    case cancelled
    
    static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.purchasing, .purchasing), (.cancelled, .cancelled):
            return true
        case let (.succeeded(lhsProduct), .succeeded(rhsProduct)):
            return lhsProduct.id == rhsProduct.id
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

enum PurchaseResult {
    case success
    case pending
    case failed(Error)
    case cancelled
}

enum StoreKitError: Error, LocalizedError {
    case productNotFound
    case purchaseFailed
    case receiptValidationFailed
    case networkError
    case invalidReceipt
    case subscriptionExpired
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in App Store"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .receiptValidationFailed:
            return "Failed to validate purchase receipt"
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidReceipt:
            return "Invalid receipt"
        case .subscriptionExpired:
            return "Subscription has expired"
        }
    }
}

@MainActor
final class StoreKitService: StoreKitServiceProtocol {
    
    // MARK: - Published Properties
    
    @Published var products: [Product] = []
    @Published var subscriptionStatus: SubscriptionStatus = SubscriptionStatus(
        tier: .free,
        isActive: false,
        expirationDate: nil,
        isInTrialPeriod: false,
        trialEndDate: nil,
        purchasedProducts: [],
        lastReceiptValidation: nil
    )
    @Published var purchaseState: PurchaseState = .idle
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private var updates: Task<Void, Never>? = nil
    private let receiptValidator: ReceiptValidator
    
    // Product IDs for subscriptions and microtransactions
    private let subscriptionProductIDs: Set<String> = [
        SubscriptionTier.premiumMonthly.productID,
        SubscriptionTier.premiumYearly.productID
    ]
    
    private let microtransactionProductIDs: Set<String> = Set(
        MicrotransactionProduct.allCases.map { $0.productID }
    )
    
    private var allProductIDs: Set<String> {
        return subscriptionProductIDs.union(microtransactionProductIDs)
    }
    
    // MARK: - Initialization
    
    init(receiptValidator: ReceiptValidator = DefaultReceiptValidator()) {
        self.receiptValidator = receiptValidator
        
        // Start listening for transaction updates
        updates = newTransactionListenerTask()
        
        // Load products and check status on init
        Task {
            do {
                try await loadProducts()
                subscriptionStatus = await checkSubscriptionStatus()
            } catch {
                print("Failed to initialize StoreKit: \(error)")
            }
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Public Methods
    
    func loadProducts() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let storeProducts = try await Product.products(for: allProductIDs)
            products = storeProducts.sorted { first, second in
                // Sort subscriptions first, then by price
                let firstIsSubscription = subscriptionProductIDs.contains(first.id)
                let secondIsSubscription = subscriptionProductIDs.contains(second.id)
                
                if firstIsSubscription && !secondIsSubscription {
                    return true
                } else if !firstIsSubscription && secondIsSubscription {
                    return false
                } else {
                    return first.price < second.price
                }
            }
        } catch {
            throw StoreKitError.networkError
        }
    }
    
    func purchase(_ product: Product) async throws -> PurchaseResult {
        guard !isLoading else { return .failed(StoreKitError.purchaseFailed) }
        
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let verifiedTransaction = try checkVerified(verification)
                
                // Update subscription status
                subscriptionStatus = await checkSubscriptionStatus()
                
                // Finish the transaction
                await verifiedTransaction.finish()
                
                purchaseState = .succeeded(product)
                return .success
                
            case .userCancelled:
                purchaseState = .cancelled
                return .cancelled
                
            case .pending:
                purchaseState = .idle
                return .pending
                
            @unknown default:
                purchaseState = .failed(StoreKitError.purchaseFailed)
                return .failed(StoreKitError.purchaseFailed)
            }
            
        } catch {
            purchaseState = .failed(error)
            return .failed(error)
        }
    }
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Sync all unfinished transactions
        try await AppStore.sync()
        
        // Update subscription status
        subscriptionStatus = await checkSubscriptionStatus()
    }
    
    func validateReceipt() async throws -> SubscriptionStatus {
        let status = try await receiptValidator.validateReceipt()
        subscriptionStatus = status
        return status
    }
    
    func checkSubscriptionStatus() async -> SubscriptionStatus {
        var currentTier: SubscriptionTier = .free
        var isActive = false
        var expirationDate: Date?
        var isInTrialPeriod = false
        var trialEndDate: Date?
        var purchasedProducts: Set<String> = []
        
        // Check current entitlements for auto-renewable subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if subscriptionProductIDs.contains(transaction.productID) {
                    if let tier = SubscriptionTier.allCases.first(where: { $0.productID == transaction.productID }) {
                        currentTier = tier
                        isActive = true
                        expirationDate = transaction.expirationDate
                        
                        // Check if in trial period
                        if let offerType = transaction.offerType, offerType == .introductory {
                            isInTrialPeriod = true
                            trialEndDate = transaction.expirationDate
                        }
                    }
                } else {
                    // Microtransaction products
                    purchasedProducts.insert(transaction.productID)
                }
                
            } catch {
                // Failed to verify transaction
                continue
            }
        }
        
        return SubscriptionStatus(
            tier: currentTier,
            isActive: isActive,
            expirationDate: expirationDate,
            isInTrialPeriod: isInTrialPeriod,
            trialEndDate: trialEndDate,
            purchasedProducts: purchasedProducts,
            lastReceiptValidation: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.receiptValidationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    
                    await MainActor.run { [weak self] in
                        Task {
                            // Update subscription status when new transactions come in
                            self?.subscriptionStatus = await self?.checkSubscriptionStatus() ?? SubscriptionStatus(
                                tier: .free,
                                isActive: false,
                                expirationDate: nil,
                                isInTrialPeriod: false,
                                trialEndDate: nil,
                                purchasedProducts: [],
                                lastReceiptValidation: nil
                            )
                        }
                    }
                    
                    await transaction?.finish()
                } catch {
                    // Handle transaction verification failure
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    func getProduct(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }
    
    func getSubscriptionProduct(for tier: SubscriptionTier) -> Product? {
        return products.first { $0.id == tier.productID }
    }
    
    func getMicrotransactionProduct(for product: MicrotransactionProduct) -> Product? {
        return products.first { $0.id == product.productID }
    }
    
    // MARK: - Family Sharing Support
    
    func checkFamilySharing() async -> Bool {
        // Check if current user has access through family sharing
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                return transaction.ownershipType == .familyShared
            } catch {
                continue
            }
        }
        return false
    }
}

// MARK: - Receipt Validation

protocol ReceiptValidator {
    func validateReceipt() async throws -> SubscriptionStatus
}

final class DefaultReceiptValidator: ReceiptValidator {
    
    func validateReceipt() async throws -> SubscriptionStatus {
        // In production, you would validate with your server
        // For now, we'll use StoreKit's local validation
        
        // Get the app receipt
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            throw StoreKitError.invalidReceipt
        }
        
        // For production, send receiptData to your server for validation
        // Your server should validate with Apple's servers
        
        // For demo purposes, we'll create a mock status
        // In real implementation, parse the validated receipt from your server
        
        return SubscriptionStatus(
            tier: .free,
            isActive: false,
            expirationDate: nil,
            isInTrialPeriod: false,
            trialEndDate: nil,
            purchasedProducts: [],
            lastReceiptValidation: Date()
        )
    }
}

// MARK: - Server Receipt Validation

struct ReceiptValidationRequest: Codable {
    let receiptData: String
    let bundleID: String
    let productID: String
}

struct ReceiptValidationResponse: Codable {
    let status: Int
    let isValid: Bool
    let expirationDate: Date?
    let isTrialPeriod: Bool?
    let purchasedProducts: [String]?
    
    enum CodingKeys: String, CodingKey {
        case status
        case isValid = "is_valid"
        case expirationDate = "expiration_date"
        case isTrialPeriod = "is_trial_period"
        case purchasedProducts = "purchased_products"
    }
}

final class ServerReceiptValidator: ReceiptValidator {
    private let validationEndpoint: URL
    private let session: URLSession
    
    init(validationEndpoint: URL, session: URLSession = .shared) {
        self.validationEndpoint = validationEndpoint
        self.session = session
    }
    
    func validateReceipt() async throws -> SubscriptionStatus {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            throw StoreKitError.invalidReceipt
        }
        
        let receiptString = receiptData.base64EncodedString()
        let request = ReceiptValidationRequest(
            receiptData: receiptString,
            bundleID: Bundle.main.bundleIdentifier ?? "",
            productID: ""
        )
        
        var urlRequest = URLRequest(url: validationEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoreKitError.networkError
        }
        
        let validationResponse = try JSONDecoder().decode(ReceiptValidationResponse.self, from: data)
        
        guard validationResponse.isValid else {
            throw StoreKitError.receiptValidationFailed
        }
        
        let tier: SubscriptionTier = validationResponse.expirationDate != nil ? .premiumMonthly : .free
        let isActive = validationResponse.expirationDate?.timeIntervalSinceNow ?? 0 > 0
        
        return SubscriptionStatus(
            tier: tier,
            isActive: isActive,
            expirationDate: validationResponse.expirationDate,
            isInTrialPeriod: validationResponse.isTrialPeriod ?? false,
            trialEndDate: validationResponse.isTrialPeriod == true ? validationResponse.expirationDate : nil,
            purchasedProducts: Set(validationResponse.purchasedProducts ?? []),
            lastReceiptValidation: Date()
        )
    }
}