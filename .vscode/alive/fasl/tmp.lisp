;;;; view.lisp
;;;; Chron-LLM v1
;;;; Analysis Layer (Phase B) - State Projection

(defpackage :phase-b.view
  (:use :cl
        :chron-llm.common
        :phase-a.event
        :phase-a.history)

  (:export
   #:view-type-count
   #:view-length
   #:view-first
   #:view-last
   #:project-to-prompt))


(in-package :phase-b.view)

;;; ============================================================
;;; Statistical Projection
;;; ============================================================

(defun view-type-count (timeline)
  "Calculates frequency distribution of event types."
  (let ((table (make-hash-table))
        (events (world-timeline-events timeline)))
    (loop for e across events do
      (incf (gethash (event-type e) table 0)))
    table))

(defun view-length (timeline)
  "Returns timeline event count."
  (length (world-timeline-events timeline)))

(defun view-first (timeline)
  "Returns first event."
  (let ((events (world-timeline-events timeline)))
    (when (> (length events) 0)
      (aref events 0))))

(defun view-last (timeline)
  "Returns latest event."
  (let ((events (world-timeline-events timeline)))
    (when (> (length events) 0)
      (aref events (1- (length events))))))

;;; ============================================================
;;; Prompt Projection
;;; ============================================================

(defun project-to-prompt (timeline)
  "Pure projection from timeline to LLM prompt stream."
  (let ((events (world-timeline-events timeline)))
    (with-output-to-string (s)
      (format s "<|begin_of_text|>~%")
      (format s "<|start_header_id|>system<|end_header_id|>~%")
      (format s "あなたは日本語で丁寧に答えるアシスタントです。~%")
      (loop for e across events do
        (format s "<|start_header_id|>~(~A~)<|end_header_id|>~%~A~%"
                (history-event-role e)
                (history-event-content e)))
      (format s "<|start_header_id|>assistant<|end_header_id|>"))))
