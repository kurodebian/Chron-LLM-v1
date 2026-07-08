;;;; llama-engine.lisp
;;;; Chron-LLM v1
;;;; Native LLM Execution Engine & Generation Orchestration
;;;;
;;;; Responsibility
;;;;    - High-level Engine state (*model*, *ctx*, *sampler*)
;;;;    - Running the generation loop using low-level physical FFI
;;;;    - Managing the mutable IR token stream for analysis
;;;;
;;;; Non Responsibility
;;;;    - Raw CFFI syntax mapping (ffi-bindings responsibility)
;;;;    - View/Prompt generation (Phase B responsibility)

(defpackage :chron-llm.llm
  (:use :cl :chron-llm.llm.ffi)
  (:export #:*model*
           #:*ctx*
           #:*sampler*
           #:*ir-stream*
           #:clear-ir-stream
           #:push-ir-event
           #:load-model
           #:init-context
           #:free-engine
           #:llama-run))

(in-package :chron-llm.llm)

;;; ============================================================
;;; 1. Engine Global State & Active IR Stream
;;; ============================================================

(defparameter *model* nil "Pointer to the loaded native llama_model.")
(defparameter *ctx* nil "Pointer to the initialized native llama_context.")
(defparameter *sampler* nil "Pointer to the active native sampler.")

(defparameter *ir-stream*
  (make-array 0 :adjustable t :fill-pointer 0)
  "Vector accumulating raw IR structures from the native C++ stream during evaluation.")

;;; ============================================================
;;; 2. Stream Control API (Called implicitly by ir-callback)
;;; ============================================================

(defun clear-ir-stream ()
  "Resets the internal IR stream for the next evaluation or trial phase."
  (setf *ir-stream* (make-array 0 :adjustable t :fill-pointer 0)))

(defun push-ir-event (ir)
  "Injected target for the physical FFI callback. Accumulates token timelines."
  (vector-push-extend ir *ir-stream*))

;;; ============================================================
;;; 3. Lifecycle & Initialization
;;; ============================================================

(defun load-model (path)
  "Loads the model into memory using the verified local FFI binding."
  (setf *model* (my-llama-model-load path))
  *model*)

(defun init-context (&key (n-ctx 2048) (temp 0.8f0) (top-p 0.9f0))
  "Initializes the safe context and its corresponding sampler, then links the IR bridge."
  (setf *ctx* (my-llama-init *model* n-ctx))
  (setf *sampler* (my-sampler-init temp top-p))
  ;; ffi-bindings側で定義したコールバックをC++側に安全に登録
  (register-ir-callback (cffi:callback chron-llm.llm.ffi::ir-callback))
  *ctx*)

(defun free-engine ()
  "Safely releases all native pointers to prevent memory leaks."
  (when *sampler* (my-sampler-free *sampler*) (setf *sampler* nil))
  (when *ctx* (my-llama-free *ctx*)       (setf *ctx* nil))
  (when *model* (my-llama-model-free *model*) (setf *model* nil)))

;;; ============================================================
;;; 4. High-Level Generation (The Orchestration Loop)
;;; ============================================================

(defun llama-run (prompt &key (max-tokens 128))
  "Orchestrates tokenization, KV-cache management, evaluation, and sampling.
   Automatically captures high-resolution IR events into *ir-stream* via CFFI callbacks."
  (clear-ir-stream)
  (my-llama-reset-kv *ctx*)
  
  ;; TODO: 開発の進捗に合わせ、以下の低レベルCAPIを回すループを肉付けします
  ;; 1. (my-llama-model-get-vocab *model*) でボキャブラリ取得
  ;; 2. cffi:with-foreign-object でバッファを確保し (my-llama-tokenize ...) を実行
  ;; 3. (my-llama-eval *ctx* ...) でKVキャッシュへ投入
  ;; 4. (my-sampler-sample *sampler* *ctx*) を EOG または max-tokens までループ
  
  "ジェネレーションの骨組みが完成！")