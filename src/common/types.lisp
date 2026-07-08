;;;; types.lisp
;;;; Chron-LLM v1
;;;; Common ABI
;;;;
;;;; Responsibility
;;;;    - Shared system data structures
;;;;    - Event ABI
;;;;    - Common constructors
;;;;
;;;; Non Responsibility
;;;;    - WAL
;;;;    - Graph
;;;;    - Runtime
;;;;    - LLM
;;;;    - Kernel logic

(in-package :chron-llm)

;;; ============================================================
;;; 1. LLM Raw Token Interface (Merged from ir.lisp)
;;; ============================================================

(defstruct (ir
             (:conc-name ir-))
  "Raw token event snapshot captured from the C++ layer via CFFI callbacks.
   Used for low-level stream profiling and dynamical analysis (Phase E)."
  ctx-id
  pos
  phase
  token
  score)

;;; ============================================================
;;; 2. Agent Conversation Interface (Merged from history.lisp)
;;; ============================================================

(defstruct (history-event
             (:conc-name history-event-))
  "High-level conversation atom representing user or assistant utterances."
  (role    :user :type symbol) ; :user, :assistant, :system
  (content ""    :type string))

;;; ============================================================
;;; 3. Event ABI (System-wide Persistent Record)
;;; ============================================================

(defstruct (event
             (:conc-name event-))
  "Persistent event record shared by all layers. 
   Can encapsulate HISTORY-EVENT or IR streams inside the payload for WAL/Causal tracking."
  ;; Position inside WAL
  (index
   0
   :type integer)

  ;; Logical clock
  (clock
   0
   :type integer)

  ;; Globally unique node identifier
  (node-id
   0
   :type integer)

  ;; World / causal lineage identifier
  (causal-id
   0
   :type integer)

  ;; Event kind (:chat, :system, :branch, etc.)
  (kind
   :unknown
   :type symbol)

  ;; User-defined payload
  (payload
   nil
   :type list))

;;; ============================================================
;;; Version
;;; ============================================================

(defconstant +event-abi-version+ 1)