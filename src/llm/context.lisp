;;;; context.lisp
;;;; Chron-LLM v1
;;;; LLM Context Layer
;;;;
;;;; Responsibility:
;;;;   - Model Initialization
;;;;   - Tokenization
;;;;   - Prompt Prefill
;;;;
;;;; Non Responsibility:
;;;;   - Session State
;;;;   - Generation
;;;;   - Runtime
;;;;   - Kernel

(in-package :chron-llm.llm)

;; 既存のパッケージ空間へ合流し、このファイルが提供するAPIを公開する
(export '(tokenize
          prefill-prompt
          init-chron-llm))

;;; ============================================================
;;; Tokenize
;;; ============================================================

(defun tokenize (model text)
  (let* ((vocab
          (my-llama-model-get-vocab model))
         (bytes
          (babel:string-to-octets
           text
           :encoding :utf-8))
         (text-len
          (length bytes)))
    (cffi:with-foreign-pointer (buf text-len)
      (loop
        for i below text-len
        do
          (setf (cffi:mem-ref buf :unsigned-char i)
                (aref bytes i)))

      ;; pass1: 必要なトークン数を算出
      (let* ((count
              (my-llama-tokenize
               vocab
               buf
               text-len
               (cffi:null-pointer)
               0
               t
               t))
             (required
              (abs count)))
        (when (zerop required)
          (error "Tokenizer returned zero tokens."))

        ;; pass2: 実際のトークン配列を確保して格納
        (cffi:with-foreign-object
            (arr :int32 required)
          (let ((count
                 (my-llama-tokenize
                  vocab
                  buf
                  text-len
                  arr
                  required
                  t
                  t)))
            (when (< count 0)
              (error
               "Tokenization failed (code=~D)."
               count))
            (loop
              for i below count
              collect
                (cffi:mem-aref arr :int32 i))))))))

;;; ============================================================
;;; Prompt Prefill
;;; ============================================================

(defun prefill-prompt (ctx tokens n-past)
  (let ((n (length tokens)))
    (cffi:with-foreign-object
        (arr :int32 n)
      (loop
        for tok in tokens
        for i from 0
        do
          (setf
           (cffi:mem-aref arr :int32 i)
           tok))
      (let ((status
             (my-llama-eval
              ctx
              arr
              n
              n-past)))
        (unless (zerop status)
          (error
           "Prefill failed (code=~D)."
           status))
        (+ n-past n)))))

;;; ============================================================
;;; Initialization
;;; ============================================================

(defun init-chron-llm
    (model-path
     &key
       (n-ctx 4096))
  (let* ((model
          (sb-int:with-float-traps-masked
              (:invalid :divide-by-zero :overflow)
            (my-llama-model-load model-path)))
         (ctx
          (sb-int:with-float-traps-masked
              (:invalid :divide-by-zero :overflow)
            (my-llama-init
             model
             n-ctx))))
    (values model ctx)))