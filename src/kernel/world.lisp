;;;; world.lisp
;;;; Chron-LLM Δ3
;;;; World Service

(in-package :chron-llm.kernel)

;; ============================================================================
;; Active Timeline
;; ============================================================================

(defstruct (world-timeline
             (:conc-name world-timeline-))
  (world-id 0 :type integer)
  (events
   (make-array 0
               :adjustable t
               :fill-pointer 0)
   :type vector))

;; ============================================================================
;; World Allocation
;; ============================================================================

(defun allocate-world-id (wal)
  (incf (wal-world-counter wal)))

;; ============================================================================
;; Branch
;; ============================================================================

(defun stage-branch-world (graph wal parent-world-id)

  (let* ((new-world-id
          (allocate-world-id wal))

         (parent-node
          (get-latest-node-in-world
           graph
           parent-world-id))

         (parent-node-id
          (if parent-node
              (causal-node-id parent-node)
              0)))

    (stage-event
     wal
     :branch
     new-world-id
     (list
      :parent-world parent-world-id
      :parent-node parent-node-id))

    new-world-id))

(defun world-timeline-branch
    (graph wal parent-timeline)

  (let* ((parent-id
          (world-timeline-world-id parent-timeline))

         (new-id
          (stage-branch-world
           graph
           wal
           parent-id)))

    (make-world-timeline
     :world-id new-id
     :events
     (copy-seq
      (world-timeline-events
       parent-timeline)))))

;; ============================================================================
;; Timeline Mutation
;; ============================================================================

(defun world-timeline-append
    (wal timeline role content)

  ;; Kernel DTO を保存
  (let ((entry
         (make-history-entry
          :kind role
          :text content
          :clock (get-universal-time))))

    (vector-push-extend
     entry
     (world-timeline-events timeline)))

  ;; WALへ記録
  (stage-event
   wal
   :chat
   (world-timeline-world-id timeline)
   (list
    :role role
    :content content))

  timeline)

(defun world-timeline-size (timeline)
  (length
   (world-timeline-events timeline)))

;; ============================================================================
;; Queries
;; ============================================================================

(defun world-exists-p (graph world-id)
  (not
   (null
    (get-latest-node-in-world
     graph
     world-id))))

(defun latest-node-in-world
    (graph world-id)

  (get-latest-node-in-world
   graph
   world-id))

(defun world-parent-node
    (graph world-id)

  (let ((node
         (latest-node-in-world
          graph
          world-id)))

    (when node

      (let ((parent-id
             (get-parent-node-id
              graph
              (causal-node-id node))))

        (and parent-id
             (gethash
              parent-id
              (causal-graph-nodes graph)))))))