#lang racket/base
;;
;; simple-oauth2 - oauth2/storage/clients.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require racket/contract)

(provide get-client
         set-client!
         load-clients
         save-clients)

;; ---------- Requirements

(require racket/bool
         racket/file
         net/url-structs
         oauth2
         oauth2/private/logging
         oauth2/private/privacy
         oauth2/private/storage)

;; ---------- Implementation

; (hash/c application-name? (client?))
(define-cached-file clients 'home-dir ".oauth2.rkt")

(define (get-client app-name)
  (log-oauth2-debug "get-client for ~a" app-name)
  (define a-client (hash-ref clients-cache app-name #f))
  (cond
    [(false? a-client)
     #f]
    [(or (false? (client-secret a-client))
         (equal? (client-secret a-client) ""))
     a-client]
    [else
     ; note, we only decrypt on access, not on load.
     (struct-copy client
                  a-client
                  [secret (decrypt-secret (client-secret a-client))])]))

(define (set-client! a-client)
  (log-oauth2-debug "set-client! ~a ~a" (client-service-name a-client) (client-id a-client))
  ; note, we always encrypt into the cache, and therefore into save.
  (define new-client
    (cond
      [(or (false? (client-secret a-client))
           (equal? (client-secret a-client) ""))
       a-client]
      [else
       (struct-copy client
                    a-client
                    [secret (encrypt-secret (client-secret a-client))])]))
  (hash-set! clients-cache (client-service-name new-client) new-client))

;; ---------- Startup procedures

(define loaded (load-clients))
(log-oauth2-info "loading clients: ~a" loaded)
