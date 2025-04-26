;; Title: BitServe - Decentralized Marketplace on Stacks
;; 
;; Summary:
;; A comprehensive decentralized marketplace leveraging Stacks and Bitcoin 
;; for secure product sales, auctions, and verified brand integration.
;;
;; Description:
;; This contract implements a feature-rich marketplace platform that enables:
;; - Brand registration and verification
;; - Direct product sales with Bitcoin-backed settlement
;; - Time-bound auctions with minimum price protection
;; - Reviewer reputation system with ratings and comments
;; - Platform fee structure for sustainability
;;
;; The marketplace connects verified sellers with buyers in a trustless environment
;; while providing robust mechanisms for price discovery through both fixed-price
;; and auction-based models.

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-brand-owner (err u101))
(define-constant err-invalid-price (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-auction-ended (err u105))
(define-constant err-bid-too-low (err u106))
(define-constant err-no-active-auction (err u107))
(define-constant err-invalid-duration (err u108))
(define-constant err-invalid-rating (err u109))
(define-constant err-transfer-failed (err u110))

;; Data Variables
(define-data-var platform-fee uint u25) ;; 2.5% fee

;; Data Maps
(define-map Brands principal 
  {
    name: (string-ascii 50),
    verified: bool,
    created-at: uint
  }
)

(define-map Products uint 
  {
    brand: principal,
    name: (string-ascii 100),
    description: (string-ascii 500),
    price: uint,
    available: bool,
    created-at: uint,
    is-auction: bool
  }
)

(define-map Auctions uint
  {
    end-block: uint,
    min-price: uint,
    highest-bid: uint,
    highest-bidder: (optional principal),
    is-active: bool
  }
)

(define-map Reviews {product-id: uint, reviewer: principal}
  {
    rating: uint,
    comment: (string-ascii 200),
    timestamp: uint
  }
)

;; Product ID counter
(define-data-var product-counter uint u0)

;; Brand Management Functions

;; Register a new brand
(define-public (register-brand (name (string-ascii 50)))
  (let
    ((brand-data {
      name: name,
      verified: false,
      created-at: stacks-block-height
    }))
    (ok (map-set Brands tx-sender brand-data))
  )
)

;; Verify a brand (owner only)
(define-public (verify-brand (brand principal))
  (if (is-eq tx-sender contract-owner)
    (let
      ((brand-data (unwrap! (map-get? Brands brand) 
                   (err err-not-brand-owner))))
      (ok (map-set Brands brand 
        (merge brand-data {verified: true}))))
    (err err-owner-only))
)

;; Direct Sale Functions

;; List a new product
(define-public (list-product 
    (name (string-ascii 100))
    (description (string-ascii 500))
    (price uint)
  )
  (let
    ((brand (unwrap! (map-get? Brands tx-sender) (err err-not-brand-owner)))
     (product-id (+ (var-get product-counter) u1)))
    
    (if (> price u0)
      (begin
        (var-set product-counter product-id)
        (ok (map-set Products product-id {
          brand: tx-sender,
          name: name,
          description: description,
          price: price,
          available: true,
          created-at: stacks-block-height,
          is-auction: false
        })))
      (err err-invalid-price)
    )
  )
)

;; Purchase a product
(define-public (purchase-product (product-id uint))
  (let
    ((product (unwrap! (map-get? Products product-id) (err err-listing-not-found)))
     (price (get price product))
     (brand (get brand product))
     (fee (/ (* price (var-get platform-fee)) u1000)))
    
    (if (and
          (get available product)
          (not (get is-auction product))
          (>= (stx-get-balance tx-sender) price))
      (let
        ((fee-transfer-result (stx-transfer? fee tx-sender contract-owner))
         (payment-transfer-result (stx-transfer? (- price fee) tx-sender brand)))
        
        (if (and 
              (is-ok fee-transfer-result)
              (is-ok payment-transfer-result))
          (ok (map-set Products product-id 
                (merge product {available: false})))
          (err err-transfer-failed)))
      (err err-insufficient-funds))
  )
)

;; Auction Functions

;; Create auction for a product
(define-public (create-auction
    (name (string-ascii 100))
    (description (string-ascii 500))
    (min-price uint)
    (duration uint)
  )
  (let
    ((brand (unwrap! (map-get? Brands tx-sender) (err err-not-brand-owner)))
     (product-id (+ (var-get product-counter) u1))
     (end-block (+ stacks-block-height duration)))
    
    (if (and (>= duration u10) (> min-price u0))
      (begin
        (var-set product-counter product-id)
        (map-set Products product-id {
          brand: tx-sender,
          name: name,
          description: description,
          price: min-price,
          available: true,
          created-at: stacks-block-height,
          is-auction: true
        })
        (ok (map-set Auctions product-id {
          end-block: end-block,
          min-price: min-price,
          highest-bid: u0,
          highest-bidder: none,
          is-active: true
        })))
      (if (< duration u10)
        (err err-invalid-duration)
        (err err-invalid-price)))
  )
)

;; Place bid on auction
(define-public (place-bid (product-id uint) (bid-amount uint))
  (let
    ((product (unwrap! (map-get? Products product-id) (err err-listing-not-found)))
     (auction (unwrap! (map-get? Auctions product-id) (err err-no-active-auction))))
    
    (if (and 
          (get is-active auction)
          (<= stacks-block-height (get end-block auction))
          (>= bid-amount (get min-price auction))
          (> bid-amount (get highest-bid auction))
          (>= (stx-get-balance tx-sender) bid-amount))
      (let
        ((return-result (match (get highest-bidder auction)
          prev-bidder (stx-transfer? (get highest-bid auction) contract-owner prev-bidder)
          (ok true)))
         (bid-result (stx-transfer? bid-amount tx-sender contract-owner)))
        
        (if (and (is-ok return-result) (is-ok bid-result))
          (ok (map-set Auctions product-id
            (merge auction {
              highest-bid: bid-amount,
              highest-bidder: (some tx-sender)
            })))
          (err err-transfer-failed)))
      ;; Replace cond with nested if statements
      (if (not (get is-active auction))
        (err err-auction-ended)
        (if (> stacks-block-height (get end-block auction))
          (err err-auction-ended)
          (if (< bid-amount (get min-price auction))
            (err err-bid-too-low)
            (if (<= bid-amount (get highest-bid auction))
              (err err-bid-too-low)
              (err err-insufficient-funds))))))
  )
)