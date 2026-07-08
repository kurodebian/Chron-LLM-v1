;;;; freeze.lisp
;;;; Chron-LLM v1
;;;; Analysis Layer (Phase F) - Semantic Freeze Layer (Normative Implementation)
;;;;
;;;; Responsibility
;;;;    - Freezing a single semantic inlet as the exclusive entry point for runtime integration.
;;;;    - Total and deterministic normalization of raw LLM streams into canonical structures.
;;;;
;;;; Non Responsibility
;;;;    - Graph execution or causal topology updates.
;;;;    - Mutating History (A), Model (C), or Graph (D) state contracts.

(in-package :chron-llm)

;;; ============================================================
;;; Phase F Structures & Types
;;; ============================================================

(deftype inlet-target ()
  '(member :history :model :graph))

(defstruct (frozen-semantics
             (:constructor %make-frozen-semantics)
             (:conc-name freeze-))
  "An immutable, versioned encapsulation of the frozen semantic inlet. (FINV-7)"
  (version    "1.0.0" :type string         :read-only t)
  (target     :history :type inlet-target  :read-only t) ; F0: inlet = A
  (inlet-fn   #'identity :type function    :read-only t))

;;; ============================================================
;;; Core Factory: frozen_semantics(config)
;;; ============================================================

(defun freeze-semantics (config)
  "Factory to instantiate a frozen semantic layer. 
   Configures and locks down exactly ONE deterministic normalization inlet. (FINV-1, FINV-4)"
  (let* ((version (getf config :version "1.0.0"))
         (target  (getf config :target :history)) ; F0 Default: inlet = A (History)
         (inlet-fn
           (ecase target
             ;; F0: Binding raw text/tokens to pristine History Event Atoms
             (:history
              (lambda (raw-llm-output)
                (unless (stringp raw-llm-output)
                  (error "FINV-2 Violation: LLM output must be a valid string for :history inlet."))
                ;; 外部の状態(A, C, D)を一切汚染せず、純粋に構造体として正規化して返す (FINV-3)
                (make-event :assistant raw-llm-output)))
             
             ;; 将来の拡張用（現時点では仕様外のため封印）
             (:model
              (error "Inlet target :model is not implemented in this version specification."))
             (:graph
              (error "Inlet target :graph is not implemented in this version specification.")))))
    
    (%make-frozen-semantics :version version
                            :target target
                            :inlet-fn inlet-fn)))

;;; ============================================================
;;; Core Accessor: semantic_inlet(F)
;;; ============================================================

(defun semantic-inlet (frozen-instance)
  "Extracts the immutable, exclusive entry point function from the frozen instance."
  (assert (frozen-semantics-p frozen-instance) nil "Provided object is not a valid Phase F instance.")
  (freeze-inlet-fn frozen-instance))

;;; ============================================================
;;; SIGMA-4 Core Operation: C2 Bind Execution
;;; ============================================================

(defun bind-llm-output (frozen-instance raw-output history model graph)
  "C2: bind(LLM_output -> inlet)
   Executes total and deterministic normalization of raw LLM outputs through the frozen inlet.
   Guarantees that no state mutation occurs on History(A), Model(C), or Graph(D). (FINV-2, FINV-3)"
  
  ;; コンテキストの不変性を表明（コンパイル警告抑制と設計意図の明示）
  (declare (ignore history model graph))
  
  (let ((inlet (semantic-inlet frozen-instance)))
    ;; 唯一アクティブな窓口に通して、完全かつ決定論的に正規化された成果物を召喚する
    (funcall inlet raw-output)))