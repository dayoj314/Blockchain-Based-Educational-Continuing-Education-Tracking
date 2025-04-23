;; Course Verification Contract
;; Confirms legitimate educational offerings

(define-data-var contract-owner principal tx-sender)

;; Data structure for course providers
(define-map course-providers
  { provider-id: principal }
  {
    name: (string-utf8 100),
    is-verified: bool
  }
)

;; Data structure for courses
(define-map courses
  { course-id: (string-utf8 20) }
  {
    title: (string-utf8 100),
    provider: principal,
    credit-hours: uint,
    specialty-area: (string-utf8 50),
    expiration: uint,
    is-verified: bool
  }
)

;; Initialize contract owner
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Register a course provider
(define-public (register-provider (name (string-utf8 100)))
  (begin
    (asserts! (is-none (map-get? course-providers { provider-id: tx-sender })) (err u2))
    (map-set course-providers
      { provider-id: tx-sender }
      {
        name: name,
        is-verified: false
      }
    )
    (ok true)
  )
)

;; Verify a course provider
(define-public (verify-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u3))
    (match (map-get? course-providers { provider-id: provider-id })
      provider (begin
        (map-set course-providers
          { provider-id: provider-id }
          (merge provider { is-verified: true })
        )
        (ok true)
      )
      (err u4)
    )
  )
)

;; Register a new course
(define-public (register-course
    (course-id (string-utf8 20))
    (title (string-utf8 100))
    (credit-hours uint)
    (specialty-area (string-utf8 50))
    (expiration uint))
  (let ((provider-status (default-to { is-verified: false } (map-get? course-providers { provider-id: tx-sender }))))
    (begin
      (asserts! (get is-verified provider-status) (err u5))
      (asserts! (is-none (map-get? courses { course-id: course-id })) (err u6))
      (map-set courses
        { course-id: course-id }
        {
          title: title,
          provider: tx-sender,
          credit-hours: credit-hours,
          specialty-area: specialty-area,
          expiration: expiration,
          is-verified: true
        }
      )
      (ok true)
    )
  )
)

;; Get course details
(define-read-only (get-course-details (course-id (string-utf8 20)))
  (match (map-get? courses { course-id: course-id })
    course (ok course)
    (err u7)
  )
)

;; Check if a course is verified
(define-read-only (is-course-verified (course-id (string-utf8 20)))
  (match (map-get? courses { course-id: course-id })
    course (ok (get is-verified course))
    (err u8)
  )
)

;; Check if a provider is verified
(define-read-only (is-provider-verified (provider-id principal))
  (match (map-get? course-providers { provider-id: provider-id })
    provider (ok (get is-verified provider))
    (err u9)
  )
)
