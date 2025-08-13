(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-invalid-status (err u105))
(define-constant err-insufficient-payment (err u106))
(define-constant err-shipment-not-verified (err u107))
(define-constant err-contract-completed (err u108))
(define-constant err-invalid-oracle (err u109))

(define-data-var next-contract-id uint u1)
(define-data-var shipping-oracle principal tx-sender)

(define-map export-contracts
  { contract-id: uint }
  {
    exporter: principal,
    importer: principal,
    tin-quantity: uint,
    price-per-ton: uint,
    total-amount: uint,
    escrow-amount: uint,
    status: (string-ascii 20),
    created-at: uint,
    shipment-date: (optional uint),
    customs-cleared: bool,
    shipping-verified: bool,
    payment-released: bool,
    customs-doc-hash: (optional (buff 32))
  }
)

(define-map user-contracts
  { user: principal }
  { contract-ids: (list 50 uint) }
)

(define-map customs-documents
  { contract-id: uint }
  {
    doc-hash: (buff 32),
    doc-type: (string-ascii 50),
    issued-by: principal,
    timestamp: uint,
    verified: bool
  }
)

(define-read-only (get-contract (contract-id uint))
  (map-get? export-contracts { contract-id: contract-id })
)

(define-read-only (get-user-contracts (user principal))
  (default-to { contract-ids: (list) } (map-get? user-contracts { user: user }))
)

(define-read-only (get-customs-document (contract-id uint))
  (map-get? customs-documents { contract-id: contract-id })
)

(define-read-only (get-next-contract-id)
  (var-get next-contract-id)
)

(define-read-only (get-shipping-oracle)
  (var-get shipping-oracle)
)

(define-public (set-shipping-oracle (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set shipping-oracle new-oracle)
    (ok true)
  )
)

(define-public (create-export-contract 
  (importer principal)
  (tin-quantity uint)
  (price-per-ton uint))
  (let
    (
      (contract-id (var-get next-contract-id))
      (total-amount (* tin-quantity price-per-ton))
      (current-contracts (get contract-ids (get-user-contracts tx-sender)))
    )
    (asserts! (> tin-quantity u0) err-invalid-amount)
    (asserts! (> price-per-ton u0) err-invalid-amount)
    
    (map-set export-contracts
      { contract-id: contract-id }
      {
        exporter: tx-sender,
        importer: importer,
        tin-quantity: tin-quantity,
        price-per-ton: price-per-ton,
        total-amount: total-amount,
        escrow-amount: u0,
        status: "created",
        created-at: burn-block-height,
        shipment-date: none,
        customs-cleared: false,
        shipping-verified: false,
        payment-released: false,
        customs-doc-hash: none
      }
    )
    
    (map-set user-contracts
      { user: tx-sender }
      { contract-ids: (unwrap! (as-max-len? (append current-contracts contract-id) u50) err-invalid-amount) }
    )
    
    (var-set next-contract-id (+ contract-id u1))
    (ok contract-id)
  )
)

(define-public (deposit-payment (contract-id uint))
  (let
    (
      (contract-info (unwrap! (get-contract contract-id) err-not-found))
      (total-amount (get total-amount contract-info))
    )
    (asserts! (is-eq tx-sender (get importer contract-info)) err-unauthorized)
    (asserts! (is-eq (get status contract-info) "created") err-invalid-status)
    (asserts! (> total-amount u0) err-invalid-amount)
    
    (try! (stx-transfer? total-amount tx-sender (as-contract tx-sender)))
    
    (map-set export-contracts
      { contract-id: contract-id }
      (merge contract-info {
        escrow-amount: total-amount,
        status: "funded"
      })
    )
    
    (ok true)
  )
)

(define-public (upload-customs-document 
  (contract-id uint)
  (doc-hash (buff 32))
  (doc-type (string-ascii 50)))
  (let
    (
      (contract-info (unwrap! (get-contract contract-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get exporter contract-info)) err-unauthorized)
    (asserts! (or (is-eq (get status contract-info) "funded") 
                  (is-eq (get status contract-info) "shipped")) err-invalid-status)
    
    (map-set customs-documents
      { contract-id: contract-id }
      {
        doc-hash: doc-hash,
        doc-type: doc-type,
        issued-by: tx-sender,
        timestamp: burn-block-height,
        verified: false
      }
    )
    
    (map-set export-contracts
      { contract-id: contract-id }
      (merge contract-info {
        customs-doc-hash: (some doc-hash),
        customs-cleared: false,
        status: "documented"
      })
    )
    
    (ok true)
  )
)

(define-public (verify-customs-clearance (contract-id uint))
  (let
    (
      (contract-info (unwrap! (get-contract contract-id) err-not-found))
      (customs-doc (unwrap! (get-customs-document contract-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status contract-info) "documented") err-invalid-status)
    
    (map-set customs-documents
      { contract-id: contract-id }
      (merge customs-doc { verified: true })
    )
    
    (map-set export-contracts
      { contract-id: contract-id }
      (merge contract-info {
        customs-cleared: true,
        status: "cleared"
      })
    )
    
    (ok true)
  )
)

(define-public (confirm-shipment (contract-id uint))
  (let
    (
      (contract-info (unwrap! (get-contract contract-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get exporter contract-info)) err-unauthorized)
    (asserts! (is-eq (get status contract-info) "cleared") err-invalid-status)
    (asserts! (get customs-cleared contract-info) err-invalid-status)
    
    (map-set export-contracts
      { contract-id: contract-id }
      (merge contract-info {
        status: "shipped",
        shipment-date: (some burn-block-height)
      })
    )
    
    (ok true)
  )
)

(define-public (verify-shipment-delivery (contract-id uint))
  (let
    (
      (contract-info (unwrap! (get-contract contract-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (var-get shipping-oracle)) err-invalid-oracle)
    (asserts! (is-eq (get status contract-info) "shipped") err-invalid-status)
    
    (map-set export-contracts
      { contract-id: contract-id }
      (merge contract-info {
        shipping-verified: true,
        status: "delivered"
      })
    )
    
    (ok true)
  )
)

(define-public (release-payment (contract-id uint))
  (let
    (
      (contract-info (unwrap! (get-contract contract-id) err-not-found))
      (escrow-amount (get escrow-amount contract-info))
      (exporter (get exporter contract-info))
    )
    (asserts! (is-eq (get status contract-info) "delivered") err-invalid-status)
    (asserts! (get shipping-verified contract-info) err-shipment-not-verified)
    (asserts! (not (get payment-released contract-info)) err-contract-completed)
    (asserts! (> escrow-amount u0) err-insufficient-payment)
    
    (try! (as-contract (stx-transfer? escrow-amount tx-sender exporter)))
    
    (map-set export-contracts
      { contract-id: contract-id }
      (merge contract-info {
        payment-released: true,
        status: "completed"
      })
    )
    
    (ok true)
  )
)

(define-public (emergency-refund (contract-id uint))
  (let
    (
      (contract-info (unwrap! (get-contract contract-id) err-not-found))
      (escrow-amount (get escrow-amount contract-info))
      (importer (get importer contract-info))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (get payment-released contract-info)) err-contract-completed)
    (asserts! (> escrow-amount u0) err-insufficient-payment)
    
    (try! (as-contract (stx-transfer? escrow-amount tx-sender importer)))
    
    (map-set export-contracts
      { contract-id: contract-id }
      (merge contract-info {
        payment-released: true,
        status: "refunded"
      })
    )
    
    (ok true)
  )
)
