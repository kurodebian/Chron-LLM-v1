;;;; ffi-bindings-mock.lisp
;;;; Chron-LLM v1
;;;; Mock Physical Layer

(in-package :chron-llm)

;;; ============================================================
;;; Mock Structures
;;; ============================================================

(defstruct mock-model
  (path "" :type string))

(defstruct mock-ctx
  model
  (context-size 4096 :type fixnum)
  (kv-past-tokens 0 :type fixnum))

(defparameter *mock-token-counter* 0)

;;; ============================================================
;;; Model
;;; ============================================================

(defun my-llama-model-load (model-path)
  (make-mock-model
   :path model-path))

(defun my-llama-init (model &optional (ctx-size 4096))
  (make-mock-ctx
   :model model
   :context-size ctx-size))

;;; ============================================================
;;; KV Cache
;;; ============================================================

(defun my-llama-kv-cache-seq-rm
    (ctx seq-id p-start p-end)

  (declare
   (ignore seq-id p-end))

  (setf
   (mock-ctx-kv-past-tokens ctx)
   p-start)

  0)

(defun my-llama-reset-kv (ctx)

  (setf
   (mock-ctx-kv-past-tokens ctx)
   0)

  0)

;;; ============================================================
;;; Evaluation
;;; ============================================================

(defun my-llama-eval
    (ctx
     tokens
     n-tokens
     n-past)

  (declare
   (ignore tokens))

  (setf
   (mock-ctx-kv-past-tokens ctx)
   (+ n-past n-tokens))

  0)

;;; ============================================================
;;; Vocabulary
;;; ============================================================

(defun my-llama-model-get-vocab (model)
  (declare (ignore model))
  :mock-vocab)

(defun my-llama-tokenize
    (vocab
     buffer
     text-length
     tokens
     max-tokens
     add-special
     parse-special)

  (declare
   (ignore
    vocab
    buffer
    text-length
    add-special
    parse-special))

  ;; Pass1
  (if (cffi:null-pointer-p tokens)
      1

      ;; Pass2
      (progn
        (setf
         (cffi:mem-aref
          tokens
          :int32
          0)
         1)

        1)))

;;; ============================================================
;;; Token Output
;;; ============================================================

(defun my-llama-token-to-piece
    (model
     token-id
     buffer
     size)

  (declare
   (ignore model token-id))

  (when (> size 0)
    (setf
     (cffi:mem-aref buffer :char 0)
     (char-code #\A)))

  1)

(defun my-llama-is-eog
    (ctx
     token-id)

  (declare
   (ignore ctx token-id))

  nil)

;;; ============================================================
;;; Sampler
;;; ============================================================

(defun my-sampler-init
    (temperature
     top-p)

  (declare
   (ignore temperature top-p))

  (setf *mock-token-counter* 0)

  :mock-sampler)

(defun my-sampler-sample
    (sampler
     ctx)

  (declare
   (ignore sampler ctx))

  (incf *mock-token-counter*))

(defun my-sampler-free (sampler)

  (declare
   (ignore sampler))

  nil)

;;; ============================================================
;;; Resource Management
;;; ============================================================

(defun my-llama-free (ctx)

  (declare
   (ignore ctx))

  nil)

(defun my-llama-model-free (model)

  (declare
   (ignore model))

  nil)