;;;; chron-llm-kernel.lisp
;;;; Chron-LLM Δ3 Kernel
;;;; Runtime <-> Kernel Boundary

(in-package :chron-llm)

;;; ============================================================================
;;; DTO
;;; ============================================================================

(defstruct history-entry
  (kind :unknown :type symbol)
  (text "" :type string)
  (clock 0 :type integer))

(defstruct context-object
  (system-prompt "" :type string)
  (history nil :type list)
  (memory-context nil :type list)
  (metadata nil :type list))

(defstruct kernel-state
  (world-id 0 :type integer)
  (health :ok :type symbol)
  (context nil :type context-object))

;;; ============================================================================
;;; Kernel Container
;;; ============================================================================

(defclass chron-kernel ()
  ((wal
    :initarg :wal
    :reader kernel-wal)

   (graph
    :initform nil
    :accessor kernel-graph)

   (current-world
    :initform 100
    :accessor kernel-current-world)))

(defun make-chron-kernel ()
  (make-instance
   'chron-kernel
   :wal (make-instance 'write-ahead-log)))

(defparameter *kernel*
  (make-chron-kernel))

(defun current-wal ()
  (kernel-wal *kernel*))

;;; ============================================================================
;;; DTO Builder
;;; ============================================================================

(defun %history->dto (history)

  (mapcar
   (lambda (node)

     (let ((ev (causal-node-event node)))

       (make-history-entry
        :kind  (event-kind ev)
        :text  (or (getf (event-payload ev) :text) "")
        :clock (event-clock ev))))

   history))

(defun kernel-build-context-view (kernel)

  (make-context-object

   :history

   (let ((graph (kernel-graph kernel)))

     (if graph
         (%history->dto
          (graph-history
           graph
           (kernel-current-world kernel)))
         nil))

   :memory-context nil
   :metadata nil))

;;; ============================================================================
;;; Projection
;;; ============================================================================

(defun refresh-projections (kernel)

  (setf
   (kernel-graph kernel)
   (rebuild-graph-from-wal
    (kernel-wal kernel)))

  kernel)

;;; ============================================================================
;;; Health
;;; ============================================================================

(defun kernel-health (kernel)

  (let ((graph (kernel-graph kernel)))

    (if graph
        (check-immune-status
         graph
         (kernel-current-world kernel))
        :ok)))

;;; ============================================================================
;;; Internal Commit
;;; ============================================================================

(defun %kernel-commit-event
    (kernel
     kind
     payload)

  (let ((wal (kernel-wal kernel)))

    (stage-event
     wal
     kind
     (kernel-current-world kernel)
     payload)

    (multiple-value-bind (ok events)

        (commit-staged wal)

      (declare (ignore events))

      (unless ok
        (error "Kernel commit failed."))

      (refresh-projections kernel)

      (kernel-current-state kernel))))

;;; ============================================================================
;;; Public API
;;; ============================================================================

(defun kernel-submit-user-input
    (kernel text)

  (%kernel-commit-event
   kernel
   :user
   (list :text text)))

(defun kernel-submit-assistant-reply
    (kernel text)

  (%kernel-commit-event
   kernel
   :assistant
   (list :text text)))

(defun kernel-current-state (kernel)

  (make-kernel-state

   :world-id
   (kernel-current-world kernel)

   :health
   (kernel-health kernel)

   :context
   (kernel-build-context-view kernel)))

;;; ============================================================================
;;; World API
;;; ============================================================================

(defun kernel-create-world (kernel)

  (let* ((graph (kernel-graph kernel))
         (wal   (kernel-wal kernel))

         (new-world
          (stage-branch-world
           graph
           wal
           (kernel-current-world kernel))))

    (multiple-value-bind (ok events)

        (commit-staged wal)

      (declare (ignore events))

      (unless ok
        (error "Branch commit failed.")))

    (setf
     (kernel-current-world kernel)
     new-world)

    (refresh-projections kernel)

    new-world))

(defun kernel-switch-world
    (kernel
     world-id)

  (unless
      (world-exists-p
       (kernel-graph kernel)
       world-id)

    (error "Unknown world: ~A" world-id))

  (setf
   (kernel-current-world kernel)
   world-id)

  (kernel-current-state kernel))