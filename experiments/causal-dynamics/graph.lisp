;;;; graph.lisp
;;;; Chron-LLM Experiments
;;;; Causal Dynamics
;;;; Graph Definition

(defpackage :experiment
  (:use :cl)
  (:export

   ;; ==========================================================
   ;; Graph Construction
   ;; ==========================================================

   #:make-3cluster-graph

   ;; ==========================================================
   ;; Graph Types
   ;; ==========================================================

   #:node
   #:edge
   #:graph

   ;; ==========================================================
   ;; Accessors
   ;; ==========================================================

   #:node-id
   #:node-role

   #:edge-from
   #:edge-to
   #:edge-relation
   #:edge-strength

   #:graph-nodes
   #:graph-edges

   ;; ==========================================================
   ;; Dynamics
   ;; ==========================================================

   #:next-event
   #:rollout*
   #:find-attractor

   ;; ==========================================================
   ;; SCC
   ;; ==========================================================

   #:compute-sccs

   ;; ==========================================================
   ;; Cycle
   ;; ==========================================================

   #:extract-cycle-from-path
   #:find-recurrent-cycle

   ;; ==========================================================
   ;; Basin
   ;; ==========================================================

   #:basin
   #:build-basin-map
   #:build-basin-structure))

(in-package :experiment)

;;; ============================================================
;;; Graph Types
;;; ============================================================

(defstruct node
  id
  role)

(defstruct edge
  from
  to
  relation
  strength)

(defstruct graph
  nodes
  edges)

;;; ============================================================
;;; Sample Graph
;;; ============================================================

(defun make-3cluster-graph ()

  (let* ((nodes
          (list
           ;; Reply cluster
           (make-node :id :a1 :role :reply)
           (make-node :id :a2 :role :reply)
           (make-node :id :a3 :role :reply)

           ;; Temporal cluster
           (make-node :id :b1 :role :temporal)
           (make-node :id :b2 :role :temporal)
           (make-node :id :b3 :role :temporal)

           ;; Bridge nodes
           (make-node :id :c1 :role :bridge)
           (make-node :id :c2 :role :bridge)))

         (edges
          (list

           ;; Reply cluster
           (make-edge
            :from :a1 :to :a2
            :relation :reply
            :strength 0.9)

           (make-edge
            :from :a2 :to :a3
            :relation :reply
            :strength 0.9)

           (make-edge
            :from :a3 :to :a1
            :relation :reply
            :strength 0.9)

           ;; Temporal cluster
           (make-edge
            :from :b1 :to :b2
            :relation :temporal
            :strength 0.3)

           (make-edge
            :from :b2 :to :b3
            :relation :temporal
            :strength 0.3)

           (make-edge
            :from :b3 :to :b1
            :relation :temporal
            :strength 0.3)

           ;; Bridge
           (make-edge
            :from :c1 :to :a1
            :relation :reply
            :strength 0.6)

           (make-edge
            :from :c1 :to :b1
            :relation :temporal
            :strength 0.4)

           (make-edge
            :from :c2 :to :a2
            :relation :reply
            :strength 0.4)

           (make-edge
            :from :c2 :to :b2
            :relation :temporal
            :strength 0.6))))

    (make-graph
     :nodes nodes
     :edges edges)))