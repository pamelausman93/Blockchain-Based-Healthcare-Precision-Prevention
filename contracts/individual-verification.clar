;; Individual Verification Contract
;; Validates health participants and manages their verification status

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-verified (err u102))

;; Data maps
(define-map verified-individuals principal bool)
(define-map individual-profiles
  principal
  {
    verified-at: uint,
    verification-level: uint,
    health-id: (string-ascii 64)
  }
)

;; Read-only functions
(define-read-only (is-verified (individual principal))
  (default-to false (map-get? verified-individuals individual))
)

(define-read-only (get-profile (individual principal))
  (map-get? individual-profiles individual)
)

;; Public functions
(define-public (verify-individual (individual principal) (health-id (string-ascii 64)) (level uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (is-verified individual)) err-already-verified)

    (map-set verified-individuals individual true)
    (map-set individual-profiles individual {
      verified-at: block-height,
      verification-level: level,
      health-id: health-id
    })

    (ok true)
  )
)

(define-public (revoke-verification (individual principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-verified individual) err-not-verified)

    (map-delete verified-individuals individual)
    (map-delete individual-profiles individual)

    (ok true)
  )
)
