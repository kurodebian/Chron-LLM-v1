;;; ============================================================================
;;; Chron-LLM Δ3
;;; Event ABI + Write Ahead Log
;;;
;;; Responsibility
;;;   - Event ABI
;;;   - WAL persistence
;;;   - Event staging
;;;   - Event commit
;;;   - Node / Clock allocation
;;;
;;; Non Responsibility
;;;   - Graph
;;;   - History
;;;   - World
;;;   - Immune
;;;   - Runtime
;;;   - Prompt
;;; ============================================================================

(in-package :chron-llm.kernel)

;; ============================================================================
;; Event ABI
;; ============================================================================

(defstruct event
  (node-id   0        :type integer)
  (clock     0        :type integer)
  (causal-id 0        :type integer)
  (kind      :unknown :type symbol)
  (payload   nil      :type list))

;; ============================================================================
;; WAL
;; ============================================================================

(defclass write-ahead-log ()
  ((storage
    :initform (make-array 64
                          :adjustable t
                          :fill-pointer 0)
    :accessor wal-storage)

   (staged-events
    :initform (make-array 8
                          :adjustable t
                          :fill-pointer 0)
    :accessor wal-staged-events)

   ;; Monotonic Logical Clock
   (clock
    :initform 0
    :accessor wal-clock)

   ;; Global Event(Node) ID
   (node-counter
    :initform 1000
    :accessor wal-node-counter)

   ;; World(Lineage) ID
   (world-counter
    :initform 100
    :accessor wal-world-counter)))

;; ============================================================================
;; Allocation
;; ============================================================================

(defun allocate-node-id (wal)
  "Allocate a globally unique node id."
  (incf (wal-node-counter wal)))

(defun allocate-clock (wal)
  "Allocate a monotonically increasing logical clock."
  (incf (wal-clock wal)))

;; ============================================================================
;; Validation
;; ============================================================================

(defun validate-event (event)
  "Phase1 Event validation."

  (assert (integerp (event-node-id event)))
  (assert (integerp (event-causal-id event)))
  (assert (symbolp (event-kind event)))
  (assert (listp (event-payload event)))

  t)

(defun invariant-check-p (wal events)
  "Batch-level invariant check.
Phase1 always succeeds."

  (declare (ignore wal events))
  t)

;; ============================================================================
;; Commit Primitive
;; ============================================================================

(defun commit-event (wal event)
  "Persist a single event."

  (validate-event event)

  (setf (event-clock event)
        (allocate-clock wal))

  (vector-push-extend
   event
   (wal-storage wal))

  event)

;; ============================================================================
;; Immediate Commit
;; ============================================================================

(defun append-event (wal kind causal-id payload)
  "Create and immediately commit an event."

  (let ((event
         (make-event
          :node-id   (allocate-node-id wal)
          :causal-id causal-id
          :kind      kind
          :payload   payload)))

    (commit-event wal event)))

;; ============================================================================
;; Stage
;; ============================================================================

(defun stage-event (wal kind causal-id payload)
  "Stage an event for later commit."

  (let ((event
         (make-event
          :node-id   (allocate-node-id wal)
          :causal-id causal-id
          :kind      kind
          :payload   payload)))

    (vector-push-extend
     event
     (wal-staged-events wal))

    event))

(defun discard-staged (wal)
  "Discard all staged events."

  (setf (fill-pointer (wal-staged-events wal))
        0)

  t)

(defun rollback-stage (wal)
  "Rollback staged events."

  (discard-staged wal))

;; ============================================================================
;; Batch Commit
;; ============================================================================

(defun commit-staged (wal)
  "Commit all staged events."

  (let ((committed-events
         (make-array 0
                     :adjustable t
                     :fill-pointer 0)))

    (when (invariant-check-p
           wal
           (wal-staged-events wal))

      (loop
        for event across (wal-staged-events wal)
        do (vector-push-extend
            (commit-event wal event)
            committed-events))

      (discard-staged wal)

      (values
       t
       committed-events))))

;; ============================================================================
;; Utility
;; ============================================================================

(defun clear-wal (wal)
  "Reset WAL to the initial state.
Mainly used for testing."

  (setf (fill-pointer (wal-storage wal)) 0)
  (setf (fill-pointer (wal-staged-events wal)) 0)

  (setf (wal-clock wal) 0)
  (setf (wal-node-counter wal) 1000)
  (setf (wal-world-counter wal) 100)

  wal)