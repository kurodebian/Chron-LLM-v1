;; ============================================================
;; Common Layer
;; ============================================================

(defpackage :chron-llm.common
  (:use :cl)
  (:export
   #:ir
   #:make-ir
   #:ir-ctx-id
   #:ir-pos
   #:ir-phase
   #:ir-token
   #:ir-score
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
   #:run-llm-generation))


;; ============================================================
;; Kernel Layer
;; ============================================================

(defpackage :chron-llm.kernel
  (:use :cl
        :chron-llm.common
        :chron-llm.llm)
  (:export
   #:make-chron-kernel

   #:kernel-submit-user-input
   #:kernel-submit-assistant-reply

   #:kernel-current-state
   #:kernel-state-world-id
   #:kernel-state-health
   #:kernel-state-context

   #:history
   #:make-history
   #:history-events
   #:history-append
   #:history-size
   #:history-copy))


;; ============================================================
;; Analysis Layer (Top-level only)
;; ============================================================

(defpackage :chron-llm.analysis
  (:use :cl
        :chron-llm.common
        :chron-llm.llm
        :chron-llm.kernel)
  (:export
   ;; Phase-B API (export only; actual package defined in phase-b/view.lisp)
   #:project-to-prompt
   #:view-last

   ;; Phase-D/E API
   #:divergence-profile
   #:log-trace
   #:save-trace-to-file))


;; ============================================================
;; Runtime Layer
;; ============================================================

(defpackage :chron-llm.runtime
  (:use :cl
        :chron-llm.llm
        :chron-llm.kernel
        :chron-llm.analysis)
  (:export
   #:start-chat
   #:agent-main-loop))


;; ============================================================
;; Agent Layer
;; ============================================================

(defpackage :chron-llm.agent
  (:use :cl
        :chron-llm.runtime)
  (:export
   #:start-delta3
   #:start-delta3-stub))
