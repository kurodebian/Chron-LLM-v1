;; ============================================================
;; Common Layer
;; ============================================================

(defpackage :chron-llm.common
  (:use :cl)
  (:export
   ;; IR
   #:ir
   #:make-ir
   #:ir-ctx-id
   #:ir-pos
   #:ir-phase
   #:ir-token
   #:ir-score
   ;; High-level conversation atom
   #:history-event
   #:make-history-event
   #:history-event-role
   #:history-event-content))

;; ============================================================
;; LLM Layer
;; ============================================================

(defpackage :chron-llm.llm
  (:use :cl
        :cffi
        :chron-llm.common)
  (:export
   #:load-model
   #:init-context
   #:llama-run
   #:init-ir-bridge
   #:*model*
   #:*ctx*
   #:*ir-stream*
   #:push-ir
   #:clear-ir-stream
   #:llm-generate-text))

;; ============================================================
;; Kernel Layer
;; ============================================================

(defpackage :chron-llm.kernel
  (:use :cl
        :chron-llm.common
        :chron-llm.llm)
  (:export
   ;; Kernel container
   #:make-chron-kernel
   #:kernel-current-state
   #:kernel-state-world-id
   #:kernel-state-health
   #:kernel-state-context

   ;; Context DTO
   #:context-object
   #:context-object-history

   ;; History-entry DTO
   #:history-entry
   #:history-entry-kind
   #:history-entry-text

   ;; Public commit API
   #:kernel-submit-user-input
   #:kernel-submit-assistant-reply

   ;; World API
   #:kernel-create-world
   #:kernel-switch-world))

;; ============================================================
;; Analysis Layer (Top-level only)
;; ============================================================

(defpackage :chron-llm.analysis
  (:use :cl
        :chron-llm.common
        :chron-llm.llm
        :chron-llm.kernel)
  (:export
   ;; Phase-B API (facade)
   #:project-to-prompt
   #:view-last
   #:view-length
   #:view-first
   #:view-type-count

   ;; Phase-E API
   #:divergence-profile
   ;; Phase-D/E trace helpers（必要なら後で追加）
   ))

;; ============================================================
;; Runtime Layer
;; ============================================================

(defpackage :chron-llm.runtime
  (:use :cl
        :chron-llm.kernel
        :chron-llm.analysis)
  (:export
   #:start-chat
   #:agent-main-loop
   #:run-llm-generation))

;; ============================================================
;; Agent Layer
;; ============================================================

(defpackage :chron-llm.agent
  (:use :cl
        :chron-llm.runtime)
  (:export
   #:start-delta3
   #:start-delta3-stub))
