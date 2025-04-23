;; Professional Verification Contract
;; Validates identity of practitioners in the system

(define-data-var contract-owner principal tx-sender)

;; Data structure for practitioners
(define-map practitioners
  { license-id: (string-utf8 20) }
  {
    name: (string-utf8 100),
    specialty: (string-utf8 50),
    license-expiry: uint,
    is-verified: bool,
    verifier: principal
  }
)

;; List of authorized verifiers
(define-map authorized-verifiers
  { verifier: principal }
  { is-authorized: bool }
)

;; Initialize contract owner
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u2))
    (map-set authorized-verifiers { verifier: verifier } { is-authorized: true })
    (ok true)
  )
)

;; Remove a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u3))
    (map-delete authorized-verifiers { verifier: verifier })
    (ok true)
  )
)

;; Register a new practitioner (unverified)
(define-public (register-practitioner
    (license-id (string-utf8 20))
    (name (string-utf8 100))
    (specialty (string-utf8 50))
    (license-expiry uint))
  (begin
    (asserts! (is-none (map-get? practitioners { license-id: license-id })) (err u4))
    (map-set practitioners
      { license-id: license-id }
      {
        name: name,
        specialty: specialty,
        license-expiry: license-expiry,
        is-verified: false,
        verifier: tx-sender
      }
    )
    (ok true)
  )
)

;; Verify a practitioner
(define-public (verify-practitioner (license-id (string-utf8 20)))
  (let ((verifier-status (default-to { is-authorized: false } (map-get? authorized-verifiers { verifier: tx-sender }))))
    (begin
      (asserts! (get is-authorized verifier-status) (err u5))
      (match (map-get? practitioners { license-id: license-id })
        practitioner (begin
          (map-set practitioners
            { license-id: license-id }
            (merge practitioner { is-verified: true, verifier: tx-sender })
          )
          (ok true)
        )
        (err u6)
      )
    )
  )
)

;; Check if a practitioner is verified
(define-read-only (is-practitioner-verified (license-id (string-utf8 20)))
  (match (map-get? practitioners { license-id: license-id })
    practitioner (ok (get is-verified practitioner))
    (err u7)
  )
)

;; Get practitioner details
(define-read-only (get-practitioner-details (license-id (string-utf8 20)))
  (match (map-get? practitioners { license-id: license-id })
    practitioner (ok practitioner)
    (err u8)
  )
)
