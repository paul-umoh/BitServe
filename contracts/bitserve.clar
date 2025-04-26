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