;; Identity Provider Verification Contract
;; Manages verification of credential issuers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_VERIFIED (err u102))

;; Data maps
(define-map verified-providers principal bool)
(define-map provider-metadata principal {
    name: (string-ascii 100),
    verification-date: uint,
    status: (string-ascii 20)
})

;; Read-only functions
(define-read-only (is-verified-provider (provider principal))
    (default-to false (map-get? verified-providers provider))
)

(define-read-only (get-provider-metadata (provider principal))
    (map-get? provider-metadata provider)
)

;; Public functions
(define-public (verify-provider (provider principal) (name (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (is-verified-provider provider)) ERR_ALREADY_VERIFIED)
        (map-set verified-providers provider true)
        (map-set provider-metadata provider {
            name: name,
            verification-date: block-height,
            status: "active"
        })
        (ok true)
    )
)

(define-public (revoke-provider (provider principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-verified-provider provider) ERR_NOT_VERIFIED)
        (map-set verified-providers provider false)
        (map-set provider-metadata provider
            (merge (unwrap-panic (get-provider-metadata provider))
                   { status: "revoked" }))
        (ok true)
    )
)
