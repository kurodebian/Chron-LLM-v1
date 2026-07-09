;;;; view.lisp
;;;; Chron-LLM v1
;;;; Analysis Layer (Phase B) - State Projection

(defpackage :phase-b.view
  (:use :cl
        :chron-llm.common
        :chron-llm.kernel)   ;; ★ Kernel DTO を参照できるように追加
  (:export
   #:view-type-count
   #:view-length
   #:view-first
   #:view-last
   #:project-to-prompt))

(in-package :phase-b.view)

;;; ============================================================
;;; Statistical Projection (context-object / history-entry)
;;; ============================================================

(defun view-type-count (context)
  "Counts event kinds in Kernel DTO history."
  (let ((table (make-hash-table))
        (events (context-object-history context)))
    (dolist (e events)
      (incf (gethash (history-entry-kind e) table 0)))
    table))

(defun view-length (context)
  "Returns number of history entries."
  (length (context-object-history context)))

(defun view-first (context)
  "Returns first history-entry."
  (first (context-object-history context)))

(defun view-last (context)
  "Returns last history-entry."
  (car (last (context-object-history context))))

;;; ============================================================
;;; Prompt Projection (Kernel DTO → LLM Prompt)
;;; ============================================================

(defun project-to-prompt (context)
  "Convert Kernel DTO history into LLM prompt stream."
  (with-output-to-string (s)

    ;; System header
    (format s "<|begin_of_text|>~%")
    (format s "<|start_header_id|>system<|end_header_id|>~%")
    (format s "あなたは日本語で丁寧に答えるアシスタントです。~%")

    ;; Dialogue history
    (dolist (e (context-object-history context))
      (format s
              "<|start_header_id|>~(~A~)<|end_header_id|>~%~A~%"
              (history-entry-kind e)
              (history-entry-text e)))

    ;; Assistant header (LLM will continue from here)
    (format s "<|start_header_id|>assistant<|end_header_id|>")))
