;; Intervention Tracking Contract
;; Monitors prevention interventions and their implementation

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-intervention-not-found (err u401))
(define-constant err-unauthorized (err u402))

;; Data structures
(define-map interventions
  uint
  {
    individual: principal,
    intervention-type: (string-ascii 64),
    description: (string-ascii 256),
    start-date: uint,
    end-date: uint,
    frequency: uint,
    status: (string-ascii 32),
    provider: principal
  }
)

(define-map intervention-logs
  {intervention-id: uint, log-id: uint}
  {
    timestamp: uint,
    activity: (string-ascii 128),
    notes: (string-ascii 256),
    compliance-score: uint
  }
)

(define-data-var intervention-counter uint u0)
(define-map intervention-log-counters uint uint)

;; Read-only functions
(define-read-only (get-intervention (intervention-id uint))
  (map-get? interventions intervention-id)
)

(define-read-only (get-intervention-log (intervention-id uint) (log-id uint))
  (map-get? intervention-logs {intervention-id: intervention-id, log-id: log-id})
)

(define-read-only (get-intervention-count)
  (var-get intervention-counter)
)

;; Public functions
(define-public (create-intervention
  (individual principal)
  (intervention-type (string-ascii 64))
  (description (string-ascii 256))
  (duration-blocks uint)
  (frequency uint))
  (let ((intervention-id (+ (var-get intervention-counter) u1)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)

      (map-set interventions intervention-id {
        individual: individual,
        intervention-type: intervention-type,
        description: description,
        start-date: block-height,
        end-date: (+ block-height duration-blocks),
        frequency: frequency,
        status: "active",
        provider: tx-sender
      })

      (map-set intervention-log-counters intervention-id u0)
      (var-set intervention-counter intervention-id)
      (ok intervention-id)
    )
  )
)

(define-public (log-intervention-activity
  (intervention-id uint)
  (activity (string-ascii 128))
  (notes (string-ascii 256))
  (compliance uint))
  (let ((log-count (default-to u0 (map-get? intervention-log-counters intervention-id)))
        (new-log-id (+ log-count u1)))
    (begin
      (asserts! (is-some (get-intervention intervention-id)) err-intervention-not-found)

      (map-set intervention-logs
        {intervention-id: intervention-id, log-id: new-log-id}
        {
          timestamp: block-height,
          activity: activity,
          notes: notes,
          compliance-score: compliance
        })

      (map-set intervention-log-counters intervention-id new-log-id)
      (ok new-log-id)
    )
  )
)

(define-public (complete-intervention (intervention-id uint))
  (let ((intervention (unwrap! (get-intervention intervention-id) err-intervention-not-found)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)

      (map-set interventions intervention-id (merge intervention {
        status: "completed",
        end-date: block-height
      }))

      (ok true)
    )
  )
)
