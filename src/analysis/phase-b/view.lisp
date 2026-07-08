;;;; view.lisp
;;;; Chron-LLM v1
;;;; Analysis Layer (Phase B) - State Projection
;;;;
;;;; Responsibility
;;;;    - Projecting world timelines into statistical summaries
;;;;    - Projecting world contexts into formatting prompts (Pure View)
;;;;
;;;; Non Responsibility
;;;;    - Mutating histories or world lines (Kernel responsibility)
;;;;    - Running FFI inference loops (LLM responsibility)

(in-package :chron-llm)

;;; ============================================================
;;; 1. Statistical Projections (Upgraded for world-timeline)
;;; ============================================================

(defun view-type-count (timeline)
  "Calculates frequency distribution of event types inside the given world-timeline."
  (let ((table (make-hash-table))
        (events (world-timeline-events timeline)))
    (loop for e across events do
      (incf (gethash (event-type e) table 0)))
    table))

(defun view-length (timeline)
  "Returns the number of dialogue steps in the timeline view."
  (length (world-timeline-events timeline)))

(defun view-first (timeline)
  "Returns the very first event of the timeline context."
  (let ((events (world-timeline-events timeline)))
    (when (> (length events) 0)
      (aref events 0))))

(defun view-last (timeline)
  "Returns the most recent event of the timeline context."
  (let ((events (world-timeline-events timeline)))
    (when (> (length events) 0)
      (aref events (1- (length events))))))

;;; ============================================================
;;; 2. Prompt Projection (Merged & Promoted from r0/prompt.lisp)
;;; ============================================================

(defun project-to-prompt (timeline)
  "Projects the historical timeline vector into a pristine Llama-3 system/user/assistant token stream.
   This is a pure statistical view projection with zero semantic intelligence."
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