;;;; ffi-bindings.lisp
;;;; Chron-LLM v1
;;;; Physical Layer (FFI)
;;;;
;;;; Responsibility:
;;;;    - CFFI bindings only
;;;;
;;;; Non Responsibility:
;;;;    - Package
;;;;    - ABI
;;;;    - Kernel
;;;;    - Runtime
;;;;    - Generation

(defpackage :chron-llm.llm.ffi
  (:use :cl :chron-llm.common)
  (:export #:llama-token
           #:my-llama-model-load
           #:my-llama-model-free
           #:my-llama-model-get-vocab
           #:my-llama-init
           #:my-llama-free
           #:my-llama-reset-kv
           #:my-llama-eval
           #:my-llama-tokenize
           #:my-llama-token-to-piece
           #:my-llama-is-eog
           #:my-sampler-init
           #:my-sampler-sample
           #:my-sampler-free
           #:register-ir-callback
           #:push-ir-event)) ; 上位レイヤー（エンジン層）で実装されるコールバックの受け口

(in-package :chron-llm.llm.ffi)

;;; ============================================================
;;; Types
;;; ============================================================

(cffi:defctype llama-token :int32)

;;; ============================================================
;;; Model
;;; ============================================================

(cffi:defcfun ("my_llama_model_load"
               my-llama-model-load)
    :pointer
  (path :string))

(cffi:defcfun ("my_llama_model_free"
               my-llama-model-free)
    :void
  (model :pointer))

(cffi:defcfun ("my_llama_model_get_vocab"
               my-llama-model-get-vocab)
    :pointer
  (model :pointer))

;;; ============================================================
;;; Context
;;; ============================================================

(cffi:defcfun ("my_llama_init"
               my-llama-init)
    :pointer
  (model :pointer)
  (n-ctx :int32))

(cffi:defcfun ("my_llama_free"
               my-llama-free)
    :void
  (ctx :pointer))

(cffi:defcfun ("my_llama_reset_kv"
               my-llama-reset-kv)
    :void
  (ctx :pointer))

;;; ============================================================
;;; Evaluation
;;; ============================================================

(cffi:defcfun ("my_llama_eval"
               my-llama-eval)
    :int32
  (ctx :pointer)
  (tokens :pointer)
  (n-tokens :int32)
  (n-past :int32))

;;; ============================================================
;;; Tokenizer
;;; ============================================================

(cffi:defcfun ("my_llama_tokenize"
               my-llama-tokenize)
    :int32
  (vocab :pointer)
  (text :pointer)
  (text-len :int32)
  (tokens :pointer)
  (n-tokens-max :int32)
  (add-special :bool)
  (parse-special :bool))

(cffi:defcfun ("my_llama_token_to_piece"
               my-llama-token-to-piece)
    :int32
  (model :pointer)
  (token-id :int32)
  (buffer :pointer)
  (buffer-size :int32))

(cffi:defcfun ("my_llama_is_eog"
               my-llama-is-eog)
    :bool
  (ctx :pointer)
  (token-id :int32))

;;; ============================================================
;;; Sampler
;;; ============================================================

(cffi:defcfun ("my_sampler_init"
               my-sampler-init)
    :pointer
  (temperature :float)
  (top-p :float))

(cffi:defcfun ("my_sampler_sample"
               my-sampler-sample)
    :int32
  (sampler :pointer)
  (ctx :pointer))

(cffi:defcfun ("my_sampler_free"
               my-sampler-free)
    :void
  (sampler :pointer))

;;; ============================================================
;;; IR Callback Bridge (Merged from runtime/ir/)
;;; ============================================================

;; コンパイル順（ASDF）による前方参照のスタイル警告を美しく抑制する
(declaim (ftype function push-ir-event))

(cffi:defcfun ("register_ir_callback" register-ir-callback) :void
  "Registers the Lisp side callback pointer into the C++ shared library."
  (cb :pointer))

(cffi:defcallback ir-callback :void
    ((ctx-id :pointer)
     (pos :int)
     (token :int)
     (score :float)
     (phase :int))
  "Direct bridge from llama.cpp loop. Converts C types to Lisp IR structures.
   MAKE-IR uses the unified ABI shared data structure from common/types.lisp."
  (push-ir-event
   (make-ir :ctx-id ctx-id
            :pos pos
            :phase phase
            :token token
            :score score)))