(in-package :chron-llm.kernel)

;;; ============================================================================
;;; Graph Projection Service
;;;
;;; Responsibility
;;;   - WAL -> Graph Projection
;;;   - Node construction
;;;   - Edge construction
;;;   - History query
;;;
;;; Non Responsibility
;;;   - Validation
;;;   - Runtime
;;;   - Prompt
;;;   - Immune
;;;   - World
;;; ============================================================================

;; ============================================================================
;; Edge
;; ============================================================================

(defstruct edge
  kind
  from
  to)

;; ============================================================================
;; Node
;; ============================================================================

(defclass causal-node ()
  ((id
    :initarg :id
    :reader causal-node-id)

   (event
    :initarg :event
    :reader causal-node-event)

   (class
    :initarg :class
    :reader causal-node-class)

   (clock
    :initarg :clock
    :reader causal-node-clock)

   (causal-id
    :initarg :causal-id
    :reader causal-node-causal-id)))

;; ============================================================================
;; Graph
;; ============================================================================

(defclass causal-graph ()
  ((nodes
    :initform (make-hash-table)
    :accessor causal-graph-nodes)

   (edges
    :initform (make-array 0
                          :adjustable t
                          :fill-pointer 0)
    :accessor causal-graph-edges)

   ;; child -> parent
   (causal-parents
    :initform (make-hash-table)
    :accessor causal-graph-causal-parents)

   ;; world-id -> latest healthy node
   (latest-healthy
    :initform (make-hash-table)
    :accessor causal-graph-latest-healthy)))

(defun make-causal-graph ()
  (make-instance 'causal-graph))

;; ============================================================================
;; Classification
;; ============================================================================

(defun determine-node-class (kind)

  (case kind

    ((:user :assistant)
     :dialogue)

    (:branch
     :branch)

    (:fault
     :fault)

    ((:system :kernel :meta)
     :system)

    (otherwise
     :system)))

;; ============================================================================
;; Projection Entry
;; ============================================================================

(defun rebuild-graph-from-wal (wal)
  "Public Projection API."

  (lift-to-graph wal))

;; ============================================================================
;; Projection
;; ============================================================================

(defun lift-to-graph (wal)

  (let ((graph (make-causal-graph))

        (last-temporal nil)

        (healthy-table
         (make-hash-table))

        (last-healthy nil))

    (loop
      for ev across (wal-storage wal)

      do

      (let* ((node
              (add-node-to-graph graph ev))

             (node-id
              (causal-node-id node)))

        ;; -----------------------------
        ;; temporal edge
        ;; -----------------------------

        (when last-temporal
          (add-edge
           graph
           :temporal
           last-temporal
           node-id))

        ;; -----------------------------
        ;; causal edge
        ;; -----------------------------

        (let ((parent
               (find-parent-node-id
                (event-causal-id ev)
                healthy-table
                last-healthy)))

          (when parent
            (add-causal-edge
             graph
             parent
             node-id)))

        ;; -----------------------------
        ;; healthy table
        ;; -----------------------------

        (unless
            (eq (causal-node-class node)
                :fault)

          (setf
           (gethash
            (event-causal-id ev)
            healthy-table)
           node-id)

          (setf last-healthy node-id))

        ;; -----------------------------

        (setf last-temporal node-id)))

    (setf
     (causal-graph-latest-healthy graph)
     healthy-table)

    graph))

;; ============================================================================
;; Node Construction
;; ============================================================================

(defun add-node-to-graph (graph event)

  (let ((node
         (make-instance
          'causal-node

          :id
          (event-node-id event)

          :event
          event

          :class
          (determine-node-class
           (event-kind event))

          :clock
          (event-clock event)

          :causal-id
          (event-causal-id event))))

    (setf
     (gethash
      (causal-node-id node)
      (causal-graph-nodes graph))
     node)

    node))

;; ============================================================================
;; Edge
;; ============================================================================

(defun add-edge (graph kind from to)

  (vector-push-extend

   (make-edge
    :kind kind
    :from from
    :to to)

   (causal-graph-edges graph)))

(defun add-causal-edge (graph from to)

  (add-edge
   graph
   :causal
   from
   to)

  (setf
   (gethash
    to
    (causal-graph-causal-parents graph))
   from))

;; ============================================================================
;; Lookup
;; ============================================================================

(defun find-parent-node-id (world-id table fallback)

  (multiple-value-bind
      (value found)

      (gethash world-id table)

    (if found
        value
        fallback)))

(defun get-parent-node-id (graph node-id)

  (gethash
   node-id
   (causal-graph-causal-parents graph)))

(defun get-latest-node-in-world (graph world-id)

  (let ((id
         (gethash world-id
                  (causal-graph-latest-healthy graph))))

    (and id
         (gethash id
                  (causal-graph-nodes graph)))))

;; ============================================================================
;; History
;; ============================================================================

(defun graph-history (graph world-id)

  (let ((node
          (get-latest-node-in-world
           graph
           world-id))
        (history nil))

    (loop while node
          do
          (when (eq (causal-node-class node)
                    :dialogue)
            (push node history))

          (setf node
                (let ((parent
                        (get-parent-node-id
                         graph
                         (causal-node-id node))))
                  (and parent
                       (gethash parent
                                (causal-graph-nodes graph))))))

    history))