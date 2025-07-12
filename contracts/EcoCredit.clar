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

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var next-credit-id uint u1)
(define-data-var platform-fee uint u250) ;; 2.5% fee (250 basis points)

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

;; Private Functions
(define-private (is-project-owner (project-id uint) (user principal))
  (match (map-get? projects { project-id: project-id })
    project-data (is-eq (get owner project-data) user)
    false
  )
)

(define-private (is-project-active (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project-data (get is-active project-data)
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

(define-private (update-user-balance (user principal) (project-id uint) (new-balance uint))
  (map-set user-balances 
    { user: user, project-id: project-id }
    { balance: new-balance }
  )
)

;; Public Functions

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
    (project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
  )
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
      (merge project-data { total-credits-issued: (+ (get total-credits-issued project-data) amount) })
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
    (asserts! (is-project-active project-id) err-project-not-active)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (asserts! (not (is-eq tx-sender recipient)) err-invalid-amount)
    
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
    (project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
  )
    (asserts! (is-project-owner project-id tx-sender) err-not-authorized)
    (asserts! (> new-price u0) err-invalid-price)
    
    (map-set projects
      { project-id: project-id }
      (merge project-data { price-per-credit: new-price })
    )
    (ok true)
  )
)

;; Deactivate a project (only project owner)
(define-public (deactivate-project (project-id uint))
  (let (
    (project-data (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
  )
    (asserts! (is-project-owner project-id tx-sender) err-not-authorized)
    
    (map-set projects
      { project-id: project-id }
      (merge project-data { is-active: false })
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

;; Check if project is active
(define-read-only (check-project-active (project-id uint))
  (is-project-active project-id)
)