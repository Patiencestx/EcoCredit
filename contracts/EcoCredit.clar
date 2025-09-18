;; EcoCredit - Carbon Credit Trading Platform with Cross-Chain Bridge
;; A decentralized platform for trading verified carbon credits across multiple blockchains

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
(define-constant err-bridge-not-active (err u113))
(define-constant err-invalid-chain-id (err u114))
(define-constant err-bridge-limit-exceeded (err u115))
(define-constant err-bridge-paused (err u116))
(define-constant err-invalid-bridge-data (err u117))
(define-constant err-bridge-already-processed (err u118))

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var next-credit-id uint u1)
(define-data-var next-oracle-id uint u1)
(define-data-var next-verification-id uint u1)
(define-data-var next-bridge-id uint u1)
(define-data-var platform-fee uint u250) ;; 2.5% fee (250 basis points)
(define-data-var oracle-threshold uint u3) ;; Minimum oracle confirmations required
(define-data-var bridge-fee uint u100) ;; 1% bridge fee (100 basis points)
(define-data-var bridge-daily-limit uint u1000000) ;; Maximum credits that can be bridged per day
(define-data-var bridge-paused bool false)

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
    is-bridged: bool,
    bridge-chain-id: (optional uint),
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
    oracle-type: (string-ascii 50),
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
    data-type: (string-ascii 50),
    measurement-value: uint,
    measurement-unit: (string-ascii 20),
    timestamp: uint,
    confidence-score: uint,
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

(define-map oracle-submission-tracker
  { block-number: uint, oracle-id: uint, project-id: uint }
  { submission-count: uint }
)

;; Cross-chain bridge maps
(define-map supported-chains
  { target-chain-id: uint }
  {
    chain-name: (string-ascii 50),
    bridge-address: (string-ascii 100),
    is-active: bool,
    daily-limit: uint,
    min-bridge-amount: uint,
    bridge-fee: uint
  }
)

(define-map bridge-requests
  { bridge-id: uint }
  {
    user: principal,
    project-id: uint,
    credit-amount: uint,
    target-chain-id: uint,
    target-address: (string-ascii 100),
    bridge-fee-paid: uint,
    status: (string-ascii 20), ;; "pending", "completed", "failed"
    created-at: uint,
    processed-at: (optional uint)
  }
)

(define-map daily-bridge-volumes
  { target-chain-id: uint, date: uint }
  { volume: uint }
)

(define-map bridge-signatures
  { bridge-id: uint, validator: principal }
  { signed: bool, signature-hash: (string-ascii 64) }
)

(define-map bridge-validators
  { validator: principal }
  { is-active: bool, stake: uint, reputation: uint }
)

;; Cross-chain bridge transaction tracking
(define-map processed-bridge-txs
  { tx-hash: (string-ascii 64) }
  { processed: bool, bridge-id: uint }
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

(define-private (is-valid-chain-id (target-chain-id uint))
  (is-some (map-get? supported-chains { target-chain-id: target-chain-id }))
)

(define-private (is-chain-active (target-chain-id uint))
  (match (map-get? supported-chains { target-chain-id: target-chain-id })
    chain-info (get is-active chain-info)
    false
  )
)

(define-private (update-user-balance (user principal) (project-id uint) (new-balance uint))
  (map-set user-balances 
    { user: user, project-id: project-id }
    { balance: new-balance }
  )
)

(define-private (can-oracle-submit (oracle-id uint) (project-id uint) (current-block uint))
  (let (
    (existing-submissions (default-to u0 
      (get submission-count 
        (map-get? oracle-submission-tracker 
          { block-number: current-block, oracle-id: oracle-id, project-id: project-id }))))
  )
    (< existing-submissions u1)
  )
)

(define-private (get-today-timestamp)
  (/ stacks-block-height u144) ;; Approximate daily blocks (144 blocks per day on Stacks)
)

(define-private (get-daily-bridge-volume (target-chain-id uint))
  (let (
    (today (get-today-timestamp))
  )
    (default-to u0 
      (get volume 
        (map-get? daily-bridge-volumes { target-chain-id: target-chain-id, date: today })
      )
    )
  )
)

(define-private (update-daily-bridge-volume (target-chain-id uint) (amount uint))
  (let (
    (today (get-today-timestamp))
    (current-volume (get-daily-bridge-volume target-chain-id))
  )
    (map-set daily-bridge-volumes
      { target-chain-id: target-chain-id, date: today }
      { volume: (+ current-volume amount) }
    )
  )
)

(define-private (calculate-bridge-fee (amount uint) (target-chain-id uint))
  (match (map-get? supported-chains { target-chain-id: target-chain-id })
    chain-info 
      (let ((fee-rate (get bridge-fee chain-info)))
        (/ (* amount fee-rate) u10000)) ;; fee-rate is in basis points
    u0 ;; Return 0 if chain not found (should not happen due to validation)
  )
)

;; Cross-chain bridge functions

;; Register a supported blockchain for bridging
(define-public (register-supported-chain
  (target-chain-id uint)
  (chain-name (string-ascii 50))
  (bridge-address (string-ascii 100))
  (daily-limit uint)
  (min-bridge-amount uint)
  (chain-bridge-fee uint)
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> target-chain-id u0) err-invalid-chain-id)
    (asserts! (> (len chain-name) u0) err-invalid-amount)
    (asserts! (> (len bridge-address) u0) err-invalid-bridge-data)
    (asserts! (> daily-limit u0) err-invalid-amount)
    (asserts! (> min-bridge-amount u0) err-invalid-amount)
    (asserts! (<= chain-bridge-fee u1000) err-invalid-bridge-data) ;; Max 10% bridge fee
    (asserts! (is-none (map-get? supported-chains { target-chain-id: target-chain-id })) err-already-exists)
    
    (map-set supported-chains
      { target-chain-id: target-chain-id }
      {
        chain-name: chain-name,
        bridge-address: bridge-address,
        is-active: true,
        daily-limit: daily-limit,
        min-bridge-amount: min-bridge-amount,
        bridge-fee: chain-bridge-fee
      }
    )
    (ok target-chain-id)
  )
)

;; Initiate bridge request to transfer credits to another chain
(define-public (initiate-bridge-transfer
  (project-id uint)
  (credit-amount uint)
  (target-chain-id uint)
  (target-address (string-ascii 100))
)
  (let (
    (bridge-id (var-get next-bridge-id))
    (user-balance (get-user-balance tx-sender project-id))
    (chain-info (unwrap! (map-get? supported-chains { target-chain-id: target-chain-id }) err-invalid-chain-id))
    (bridge-fee-amount (calculate-bridge-fee credit-amount target-chain-id))
    (total-needed (+ credit-amount bridge-fee-amount))
    (current-daily-volume (get-daily-bridge-volume target-chain-id))
    (chain-daily-limit (get daily-limit chain-info))
    (chain-min-amount (get min-bridge-amount chain-info))
    (current-block stacks-block-height)
  )
    (asserts! (not (var-get bridge-paused)) err-bridge-paused)
    (asserts! (is-valid-project-id project-id) err-not-found)
    (asserts! (is-project-active project-id) err-project-not-active)
    (asserts! (is-chain-active target-chain-id) err-bridge-not-active)
    (asserts! (> credit-amount u0) err-invalid-amount)
    (asserts! (>= credit-amount chain-min-amount) err-invalid-amount)
    (asserts! (>= user-balance total-needed) err-insufficient-balance)
    (asserts! (> (len target-address) u0) err-invalid-bridge-data)
    (asserts! (<= (+ current-daily-volume credit-amount) chain-daily-limit) err-bridge-limit-exceeded)
    
    ;; Deduct credits and fees from user balance
    (update-user-balance tx-sender project-id (- user-balance total-needed))
    
    ;; Update daily bridge volume
    (update-daily-bridge-volume target-chain-id credit-amount)
    
    ;; Create bridge request
    (map-set bridge-requests
      { bridge-id: bridge-id }
      {
        user: tx-sender,
        project-id: project-id,
        credit-amount: credit-amount,
        target-chain-id: target-chain-id,
        target-address: target-address,
        bridge-fee-paid: bridge-fee-amount,
        status: "pending",
        created-at: current-block,
        processed-at: none
      }
    )
    
    (var-set next-bridge-id (+ bridge-id u1))
    (ok bridge-id)
  )
)

;; Complete bridge transfer (validator function)
(define-public (complete-bridge-transfer
  (bridge-id uint)
  (tx-hash (string-ascii 64))
)
  (let (
    (bridge-request (unwrap! (map-get? bridge-requests { bridge-id: bridge-id }) err-not-found))
    (validator-info (unwrap! (map-get? bridge-validators { validator: tx-sender }) err-not-authorized))
    (current-block stacks-block-height)
  )
    (asserts! (> bridge-id u0) err-invalid-amount)
    (asserts! (get is-active validator-info) err-not-authorized)
    (asserts! (is-eq (get status bridge-request) "pending") err-bridge-already-processed)
    (asserts! (> (len tx-hash) u0) err-invalid-bridge-data)
    (asserts! (is-none (map-get? processed-bridge-txs { tx-hash: tx-hash })) err-already-exists)
    
    ;; Mark transaction as processed
    (map-set processed-bridge-txs
      { tx-hash: tx-hash }
      { processed: true, bridge-id: bridge-id }
    )
    
    ;; Update bridge request status
    (map-set bridge-requests
      { bridge-id: bridge-id }
      (merge bridge-request { 
        status: "completed", 
        processed-at: (some current-block) 
      })
    )
    
    (ok true)
  )
)

;; Register bridge validator
(define-public (register-bridge-validator (validator principal) (stake uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-standard validator) err-invalid-principal)
    (asserts! (> stake u0) err-invalid-amount)
    (asserts! (is-none (map-get? bridge-validators { validator: validator })) err-already-exists)
    
    (map-set bridge-validators
      { validator: validator }
      {
        is-active: true,
        stake: stake,
        reputation: u100
      }
    )
    (ok true)
  )
)

;; Pause/unpause bridge operations
(define-public (set-bridge-pause (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set bridge-paused paused)
    (ok paused)
  )
)

;; Update chain status
(define-public (update-chain-status (target-chain-id uint) (is-active bool))
  (let (
    (chain-info (unwrap! (map-get? supported-chains { target-chain-id: target-chain-id }) err-invalid-chain-id))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> target-chain-id u0) err-invalid-chain-id)
    
    (map-set supported-chains
      { target-chain-id: target-chain-id }
      (merge chain-info { is-active: is-active })
    )
    (ok true)
  )
)

;; Oracle management functions

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
    (verification-id (var-get next-verification-id))
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
    (asserts! (can-oracle-submit oracle-id project-id current-block) err-already-exists)
    
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
    
    (map-set oracle-submission-tracker
      { block-number: current-block, oracle-id: oracle-id, project-id: project-id }
      { submission-count: u1 }
    )
    
    (var-set next-verification-id (+ verification-id u1))
    (ok verification-id)
  )
)

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
    (asserts! (not (get is-verified oracle-entry)) err-already-exists)
    
    (map-set oracle-data
      { verification-id: verification-id }
      (merge oracle-entry { is-verified: true })
    )
    
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
    
    (map-set carbon-credits
      { credit-id: credit-id }
      {
        project-id: project-id,
        owner: tx-sender,
        amount: amount,
        vintage-year: vintage-year,
        verification-hash: verification-hash,
        is-retired: false,
        is-bridged: false,
        bridge-chain-id: none,
        created-at: current-block
      }
    )
    
    (update-user-balance tx-sender project-id (+ current-balance amount))
    
    (map-set projects
      { project-id: project-id }
      (merge project-info { total-credits-issued: (+ (get total-credits-issued project-info) amount) })
    )
    
    (var-set next-credit-id (+ credit-id u1))
    (ok credit-id)
  )
)

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

;; Core platform functions

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
    
    (map-set carbon-credits
      { credit-id: credit-id }
      {
        project-id: project-id,
        owner: tx-sender,
        amount: amount,
        vintage-year: vintage-year,
        verification-hash: verification-hash,
        is-retired: false,
        is-bridged: false,
        bridge-chain-id: none,
        created-at: current-block
      }
    )
    
    (update-user-balance tx-sender project-id (+ current-balance amount))
    
    (map-set projects
      { project-id: project-id }
      (merge project-info { total-credits-issued: (+ (get total-credits-issued project-info) amount) })
    )
    
    (var-set next-credit-id (+ credit-id u1))
    (ok credit-id)
  )
)

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
    
    (update-user-balance tx-sender project-id (- sender-balance amount))
    (update-user-balance recipient project-id (+ recipient-balance amount))
    
    (ok true)
  )
)

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
    
    (update-user-balance tx-sender project-id (- user-balance amount))
    (ok true)
  )
)

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

(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-credit (credit-id uint))
  (map-get? carbon-credits { credit-id: credit-id })
)

(define-read-only (get-balance (user principal) (project-id uint))
  (get-user-balance user project-id)
)

(define-read-only (get-next-project-id)
  (var-get next-project-id)
)

(define-read-only (get-next-credit-id)
  (var-get next-credit-id)
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

(define-read-only (check-project-owner (project-id uint) (user principal))
  (is-project-owner project-id user)
)

;; Oracle read-only functions

(define-read-only (get-oracle-provider (oracle-id uint))
  (map-get? oracle-providers { oracle-id: oracle-id })
)

(define-read-only (get-oracle-data (verification-id uint))
  (map-get? oracle-data { verification-id: verification-id })
)

(define-read-only (get-project-oracle-approvals (project-id uint) (oracle-id uint))
  (map-get? project-oracle-approvals { project-id: project-id, oracle-id: oracle-id })
)

(define-read-only (get-total-oracle-approvals (project-id uint))
  (get-oracle-approvals project-id)
)

(define-read-only (get-oracle-threshold)
  (var-get oracle-threshold)
)

(define-read-only (get-next-oracle-id)
  (var-get next-oracle-id)
)

(define-read-only (get-next-verification-id)
  (var-get next-verification-id)
)

(define-read-only (check-project-active (project-id uint))
  (is-project-active project-id)
)

(define-read-only (check-oracle-valid (oracle-id uint))
  (is-valid-oracle-id oracle-id)
)

(define-read-only (check-project-valid (project-id uint))
  (is-valid-project-id project-id)
)

(define-read-only (check-verification-valid (verification-id uint))
  (is-valid-verification-id verification-id)
)

(define-read-only (get-oracle-submission-count (oracle-id uint) (project-id uint) (block-number uint))
  (default-to u0 
    (get submission-count 
      (map-get? oracle-submission-tracker 
        { block-number: block-number, oracle-id: oracle-id, project-id: project-id })))
)

;; Cross-chain bridge read-only functions

(define-read-only (get-supported-chain (target-chain-id uint))
  (map-get? supported-chains { target-chain-id: target-chain-id })
)

(define-read-only (get-bridge-request (bridge-id uint))
  (map-get? bridge-requests { bridge-id: bridge-id })
)

(define-read-only (get-bridge-validator (validator principal))
  (map-get? bridge-validators { validator: validator })
)

(define-read-only (get-daily-bridge-volume-for-chain (target-chain-id uint))
  (get-daily-bridge-volume target-chain-id)
)

(define-read-only (get-bridge-fee)
  (var-get bridge-fee)
)

(define-read-only (get-bridge-daily-limit)
  (var-get bridge-daily-limit)
)

(define-read-only (get-next-bridge-id)
  (var-get next-bridge-id)
)

(define-read-only (is-bridge-paused)
  (var-get bridge-paused)
)

(define-read-only (check-chain-valid (target-chain-id uint))
  (is-valid-chain-id target-chain-id)
)

(define-read-only (check-chain-active (target-chain-id uint))
  (is-chain-active target-chain-id)
)

(define-read-only (get-bridge-fee-for-amount (amount uint) (target-chain-id uint))
  (if (is-valid-chain-id target-chain-id)
    (ok (calculate-bridge-fee amount target-chain-id))
    err-invalid-chain-id
  )
)

(define-read-only (is-bridge-tx-processed (tx-hash (string-ascii 64)))
  (is-some (map-get? processed-bridge-txs { tx-hash: tx-hash }))
)

(define-read-only (get-processed-bridge-tx (tx-hash (string-ascii 64)))
  (map-get? processed-bridge-txs { tx-hash: tx-hash })
)