;; EcoCredit - Carbon Credit Trading Platform
;; A decentralized platform for trading verified carbon credits

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-not-authorized (err u105))
(define-constant err-invalid-price (err u106))
(define-constant err-project-not-active (err u107))
(define-constant err-invalid-verification (err u108))
(define-constant err-oracle-not-authorized (err u109))
(define-constant err-invalid-oracle-data (err u110))
(define-constant err-verification-failed (err u111))
(define-constant err-invalid-principal (err u112))

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var next-credit-id uint u1)
(define-data-var next-oracle-id uint u1)
(define-data-var next-verification-id uint u1) ;; Add proper verification ID counter
(define-data-var platform-fee uint u250) ;; 2.5% fee (250 basis points)
(define-data-var oracle-threshold uint u3) ;; Minimum oracle confirmations required

;; Data Maps
(define-map projects 
  { project-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    owner: principal,
    location: (string-ascii 100),
    verification-standard: (string-ascii 50),
    is-active: bool,
    total-credits-issued: uint,
    price-per-credit: uint,
    created-at: uint
  }
)

(define-map carbon-credits
  { credit-id: uint }
  {
    project-id: uint,
    owner: principal,
    amount: uint,
    vintage-year: uint,
    verification-hash: (string-ascii 64),
    is-retired: bool,
    created-at: uint
  }
)

(define-map user-balances
  { user: principal, project-id: uint }
  { balance: uint }
)

(define-map project-verifiers
  { project-id: uint, verifier: principal }
  { is-authorized: bool }
)

;; Oracle data maps
(define-map oracle-providers
  { oracle-id: uint }
  {
    provider: principal,
    oracle-type: (string-ascii 50), ;; "IoT", "Satellite", "Manual"
    is-active: bool,
    reputation-score: uint,
    created-at: uint
  }
)

(define-map oracle-data
  { verification-id: uint }
  {
    project-id: uint,
    oracle-id: uint,
    data-type: (string-ascii 50), ;; "carbon-sequestration", "tree-count", "area-coverage"
    measurement-value: uint,
    measurement-unit: (string-ascii 20),
    timestamp: uint,
    confidence-score: uint, ;; 0-100
    geolocation: (string-ascii 100),
    is-verified: bool
  }
)

(define-map project-oracle-approvals
  { project-id: uint, oracle-id: uint }
  { 
    approval-count: uint,
    last-verification: uint,
    total-measurements: uint
  }
)

;; Add mapping to prevent duplicate submissions from same oracle for same project in same block
(define-map oracle-submission-tracker
  { block-number: uint, oracle-id: uint, project-id: uint }
  { submission-count: uint }
)

;; Private Functions
(define-private (is-project-owner (project-id uint) (user principal))
  (match (map-get? projects { project-id: project-id })
    project-info (is-eq (get owner project-info) user)
    false
  )
)

(define-private (is-project-active (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project-info (get is-active project-info)
    false
  )
)

(define-private (get-user-balance (user principal) (project-id uint))
  (default-to u0 
    (get balance 
      (map-get? user-balances { user: user, project-id: project-id })
    )
  )
)

(define-private (get-oracle-approvals (project-id uint))
  (let (
    (oracle-1 (default-to u0 (get approval-count (map-get? project-oracle-approvals { project-id: project-id, oracle-id: u1 }))))
    (oracle-2 (default-to u0 (get approval-count (map-get? project-oracle-approvals { project-id: project-id, oracle-id: u2 }))))
    (oracle-3 (default-to u0 (get approval-count (map-get? project-oracle-approvals { project-id: project-id, oracle-id: u3 }))))
  )
    (+ oracle-1 oracle-2 oracle-3)
  )
)

(define-private (is-oracle-authorized (oracle-id uint))
  (match (map-get? oracle-providers { oracle-id: oracle-id })
    provider-info (get is-active provider-info)
    false
  )
)

(define-private (is-valid-oracle-id (oracle-id uint))
  (and 
    (> oracle-id u0)
    (< oracle-id (var-get next-oracle-id))
  )
)

(define-private (is-valid-project-id (project-id uint))
  (and 
    (> project-id u0)
    (< project-id (var-get next-project-id))
  )
)

(define-private (is-valid-verification-id (verification-id uint))
  (and 
    (> verification-id u0)
    (< verification-id (var-get next-verification-id))
  )
)

(define-private (update-user-balance (user principal) (project-id uint) (new-balance uint))
  (map-set user-balances 
    { user: user, project-id: project-id }
    { balance: new-balance }
  )
)

;; Helper function to check if oracle can submit data for this project in this block
(define-private (can-oracle-submit (oracle-id uint) (project-id uint) (current-block uint))
  (let (
    (existing-submissions (default-to u0 
      (get submission-count 
        (map-get? oracle-submission-tracker 
          { block-number: current-block, oracle-id: oracle-id, project-id: project-id }))))
  )
    (< existing-submissions u1) ;; Allow only 1 submission per oracle per project per block
  )
)

;; Oracle management functions

;; Register a new oracle provider
(define-public (register-oracle 
  (oracle-type (string-ascii 50))
  (provider principal)
)
  (let (
    (oracle-id (var-get next-oracle-id))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> (len oracle-type) u0) err-invalid-amount)
    (asserts! (is-standard provider) err-invalid-principal)
    
    (map-set oracle-providers
      { oracle-id: oracle-id }
      {
        provider: provider,
        oracle-type: oracle-type,
        is-active: true,
        reputation-score: u100,
        created-at: current-block
      }
    )
    
    (var-set next-oracle-id (+ oracle-id u1))
    (ok oracle-id)
  )
)

;; Submit oracle data for verification - FIXED VERSION
(define-public (submit-oracle-data
  (project-id uint)
  (oracle-id uint)
  (data-type (string-ascii 50))
  (measurement-value uint)
  (measurement-unit (string-ascii 20))
  (confidence-score uint)
  (geolocation (string-ascii 100))
)
  (let (
    (verification-id (var-get next-verification-id)) ;; Use proper counter instead of calculation
    (current-block stacks-block-height)
    (oracle-provider (unwrap! (map-get? oracle-providers { oracle-id: oracle-id }) err-not-found))
  )
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (is-valid-oracle-id oracle-id) err-not-found)
    (asserts! (is-eq tx-sender (get provider oracle-provider)) err-oracle-not-authorized)
    (asserts! (is-oracle-authorized oracle-id) err-oracle-not-authorized)
    (asserts! (is-project-active project-id) err-project-not-active)
    (asserts! (> (len data-type) u0) err-invalid-amount)
    (asserts! (> measurement-value u0) err-invalid-amount)
    (asserts! (> (len measurement-unit) u0) err-invalid-amount)
    (asserts! (<= confidence-score u100) err-invalid-oracle-data)
    (asserts! (> (len geolocation) u0) err-invalid-amount)
    
    ;; Check if oracle can submit data for this project in this block
    (asserts! (can-oracle-submit oracle-id project-id current-block) err-already-exists)
    
    ;; Record the oracle data with proper verification ID
    (map-set oracle-data
      { verification-id: verification-id }
      {
        project-id: project-id,
        oracle-id: oracle-id,
        data-type: data-type,
        measurement-value: measurement-value,
        measurement-unit: measurement-unit,
        timestamp: current-block,
        confidence-score: confidence-score,
        geolocation: geolocation,
        is-verified: false
      }
    )
    
    ;; Update submission tracker
    (map-set oracle-submission-tracker
      { block-number: current-block, oracle-id: oracle-id, project-id: project-id }
      { submission-count: u1 }
    )
    
    ;; Increment verification ID counter
    (var-set next-verification-id (+ verification-id u1))
    
    (ok verification-id)
  )
)

;; Verify oracle data and approve project for credit issuance
(define-public (verify-oracle-data (verification-id uint))
  (let (
    (oracle-entry (unwrap! (map-get? oracle-data { verification-id: verification-id }) err-not-found))
    (project-id (get project-id oracle-entry))
    (oracle-id (get oracle-id oracle-entry))
    (current-approvals (default-to { approval-count: u0, last-verification: u0, total-measurements: u0 } 
                        (map-get? project-oracle-approvals { project-id: project-id, oracle-id: oracle-id })))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-verification-id verification-id) err-not-found)
    (asserts! (>= (get confidence-score oracle-entry) u70) err-verification-failed)
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (is-valid-oracle-id oracle-id) err-not-found)
    (asserts! (not (get is-verified oracle-entry)) err-already-exists) ;; Prevent double verification
    
    ;; Mark oracle data as verified
    (map-set oracle-data
      { verification-id: verification-id }
      (merge oracle-entry { is-verified: true })
    )
    
    ;; Update project oracle approvals
    (map-set project-oracle-approvals
      { project-id: project-id, oracle-id: oracle-id }
      {
        approval-count: (+ (get approval-count current-approvals) u1),
        last-verification: current-block,
        total-measurements: (+ (get total-measurements current-approvals) u1)
      }
    )
    
    (ok true)
  )
)

;; Enhanced credit issuance with oracle verification requirement
(define-public (issue-credits-with-oracle-verification
  (project-id uint)
  (amount uint)
  (vintage-year uint)
  (verification-hash (string-ascii 64))
)
  (let (
    (credit-id (var-get next-credit-id))
    (current-block stacks-block-height)
    (current-balance (get-user-balance tx-sender project-id))
    (project-info (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    (oracle-approvals (get-oracle-approvals project-id))
    (threshold (var-get oracle-threshold))
  )
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (is-project-owner project-id tx-sender) err-not-authorized)
    (asserts! (is-project-active project-id) err-project-not-active)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> vintage-year u2000) err-invalid-amount)
    (asserts! (> (len verification-hash) u0) err-invalid-verification)
    (asserts! (>= oracle-approvals threshold) err-verification-failed)
    
    ;; Create the credit
    (map-set carbon-credits
      { credit-id: credit-id }
      {
        project-id: project-id,
        owner: tx-sender,
        amount: amount,
        vintage-year: vintage-year,
        verification-hash: verification-hash,
        is-retired: false,
        created-at: current-block
      }
    )
    
    ;; Update user balance
    (update-user-balance tx-sender project-id (+ current-balance amount))
    
    ;; Update project total
    (map-set projects
      { project-id: project-id }
      (merge project-info { total-credits-issued: (+ (get total-credits-issued project-info) amount) })
    )
    
    (var-set next-credit-id (+ credit-id u1))
    (ok credit-id)
  )
)

;; Deactivate an oracle provider
(define-public (deactivate-oracle (oracle-id uint))
  (let (
    (provider-info (unwrap! (map-get? oracle-providers { oracle-id: oracle-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-oracle-id oracle-id) err-not-found)
    
    (map-set oracle-providers
      { oracle-id: oracle-id }
      (merge provider-info { is-active: false })
    )
    (ok true)
  )
)

;; Register a new carbon credit project
(define-public (register-project 
  (name (string-ascii 100))
  (description (string-ascii 500))
  (location (string-ascii 100))
  (verification-standard (string-ascii 50))
  (price-per-credit uint)
)
  (let (
    (project-id (var-get next-project-id))
    (current-block stacks-block-height)
  )
    (asserts! (> (len name) u0) err-invalid-amount)
    (asserts! (> (len description) u0) err-invalid-amount)
    (asserts! (> (len location) u0) err-invalid-amount)
    (asserts! (> (len verification-standard) u0) err-invalid-amount)
    (asserts! (> price-per-credit u0) err-invalid-price)
    
    (map-set projects
      { project-id: project-id }
      {
        name: name,
        description: description,
        owner: tx-sender,
        location: location,
        verification-standard: verification-standard,
        is-active: true,
        total-credits-issued: u0,
        price-per-credit: price-per-credit,
        created-at: current-block
      }
    )
    
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Issue carbon credits for a project
(define-public (issue-credits 
  (project-id uint)
  (amount uint)
  (vintage-year uint)
  (verification-hash (string-ascii 64))
)
  (let (
    (credit-id (var-get next-credit-id))
    (current-block stacks-block-height)
    (current-balance (get-user-balance tx-sender project-id))
    (project-info (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
  )
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (is-project-owner project-id tx-sender) err-not-authorized)
    (asserts! (is-project-active project-id) err-project-not-active)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> vintage-year u2000) err-invalid-amount)
    (asserts! (> (len verification-hash) u0) err-invalid-verification)
    
    ;; Create the credit
    (map-set carbon-credits
      { credit-id: credit-id }
      {
        project-id: project-id,
        owner: tx-sender,
        amount: amount,
        vintage-year: vintage-year,
        verification-hash: verification-hash,
        is-retired: false,
        created-at: current-block
      }
    )
    
    ;; Update user balance
    (update-user-balance tx-sender project-id (+ current-balance amount))
    
    ;; Update project total
    (map-set projects
      { project-id: project-id }
      (merge project-info { total-credits-issued: (+ (get total-credits-issued project-info) amount) })
    )
    
    (var-set next-credit-id (+ credit-id u1))
    (ok credit-id)
  )
)

;; Transfer carbon credits between users
(define-public (transfer-credits 
  (project-id uint)
  (recipient principal)
  (amount uint)
)
  (let (
    (sender-balance (get-user-balance tx-sender project-id))
    (recipient-balance (get-user-balance recipient project-id))
  )
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (is-project-active project-id) err-project-not-active)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (asserts! (not (is-eq tx-sender recipient)) err-invalid-amount)
    (asserts! (is-standard recipient) err-invalid-principal)
    
    ;; Update balances
    (update-user-balance tx-sender project-id (- sender-balance amount))
    (update-user-balance recipient project-id (+ recipient-balance amount))
    
    (ok true)
  )
)

;; Retire carbon credits (permanently remove from circulation)
(define-public (retire-credits 
  (project-id uint)
  (amount uint)
  (retirement-reason (string-ascii 200))
)
  (let (
    (user-balance (get-user-balance tx-sender project-id))
  )
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= user-balance amount) err-insufficient-balance)
    (asserts! (> (len retirement-reason) u0) err-invalid-amount)
    
    ;; Update user balance
    (update-user-balance tx-sender project-id (- user-balance amount))
    
    (ok true)
  )
)

;; Update project price (only project owner)
(define-public (update-project-price 
  (project-id uint)
  (new-price uint)
)
  (let (
    (project-info (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
  )
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (is-project-owner project-id tx-sender) err-not-authorized)
    (asserts! (> new-price u0) err-invalid-price)
    
    (map-set projects
      { project-id: project-id }
      (merge project-info { price-per-credit: new-price })
    )
    (ok true)
  )
)

;; Deactivate a project (only project owner)
(define-public (deactivate-project (project-id uint))
  (let (
    (project-info (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
  )
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (is-project-owner project-id tx-sender) err-not-authorized)
    
    (map-set projects
      { project-id: project-id }
      (merge project-info { is-active: false })
    )
    (ok true)
  )
)

;; Read-only functions

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get carbon credit details
(define-read-only (get-credit (credit-id uint))
  (map-get? carbon-credits { credit-id: credit-id })
)

;; Get user balance for a specific project
(define-read-only (get-balance (user principal) (project-id uint))
  (get-user-balance user project-id)
)

;; Get current project counter
(define-read-only (get-next-project-id)
  (var-get next-project-id)
)

;; Get current credit counter
(define-read-only (get-next-credit-id)
  (var-get next-credit-id)
)

;; Get platform fee
(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

;; Check if user is project owner
(define-read-only (check-project-owner (project-id uint) (user principal))
  (is-project-owner project-id user)
)

;; Oracle read-only functions

;; Get oracle provider details
(define-read-only (get-oracle-provider (oracle-id uint))
  (map-get? oracle-providers { oracle-id: oracle-id })
)

;; Get oracle data entry
(define-read-only (get-oracle-data (verification-id uint))
  (map-get? oracle-data { verification-id: verification-id })
)

;; Get project oracle approvals
(define-read-only (get-project-oracle-approvals (project-id uint) (oracle-id uint))
  (map-get? project-oracle-approvals { project-id: project-id, oracle-id: oracle-id })
)

;; Get total oracle approvals for a project
(define-read-only (get-total-oracle-approvals (project-id uint))
  (get-oracle-approvals project-id)
)

;; Get oracle threshold
(define-read-only (get-oracle-threshold)
  (var-get oracle-threshold)
)

;; Get next oracle ID
(define-read-only (get-next-oracle-id)
  (var-get next-oracle-id)
)

;; Get next verification ID
(define-read-only (get-next-verification-id)
  (var-get next-verification-id)
)

;; Check if project is active
(define-read-only (check-project-active (project-id uint))
  (is-project-active project-id)
)

;; Check if oracle is valid
(define-read-only (check-oracle-valid (oracle-id uint))
  (is-valid-oracle-id oracle-id)
)

;; Check if project is valid
(define-read-only (check-project-valid (project-id uint))
  (is-valid-project-id project-id)
)

;; Check if verification ID is valid
(define-read-only (check-verification-valid (verification-id uint))
  (is-valid-verification-id verification-id)
)

;; Get oracle submission count for a specific oracle/project/block
(define-read-only (get-oracle-submission-count (oracle-id uint) (project-id uint) (block-number uint))
  (default-to u0 
    (get submission-count 
      (map-get? oracle-submission-tracker 
        { block-number: block-number, oracle-id: oracle-id, project-id: project-id }))))