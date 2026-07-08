;;;; scc.lisp
;;;; Chron-LLM Experiments
;;;; Causal Dynamics
;;;; Strongly Connected Components

(defpackage :phase-e.scc
  (:use :cl
        :phase-d.graph
        :phase-d.edge)
  (:export #:successors
           #:predecessors
           #:compute-sccs))

(in-package :phase-e.scc)

;;; ============================================================
;;; Graph Traversal
;;; ============================================================

(defun successors (graph node)
  "Return all successor nodes of NODE."
  (mapcar #'edge-to
          (remove-if-not
           (lambda (edge)
             (eq (edge-from edge) node))
           (graph-edges graph))))

(defun predecessors (graph node)
  "Return all predecessor nodes of NODE."
  (mapcar #'edge-from
          (remove-if-not
           (lambda (edge)
             (eq (edge-to edge) node))
           (graph-edges graph))))

;;; ============================================================
;;; Depth-First Search
;;; ============================================================

(defun dfs-order (graph nodes)
  (let ((visited (make-hash-table :test #'eq))
        (order '()))
    (labels ((visit (node)
               (unless (gethash node visited)
                 (setf (gethash node visited) t)
                 (dolist (next
                          (successors graph node))
                   (visit next))
                 (push node order))))
      (dolist (node nodes)
        (visit node))
      order)))

(defun dfs-component (graph start visited)
  (let ((stack (list start))
        (component '()))
    (setf (gethash start visited) t)
    (loop
      while stack
      for node = (pop stack)
      do
        (push node component)
        (dolist (prev
                 (predecessors graph node))
          (unless (gethash prev visited)
            (setf (gethash prev visited) t)
            (push prev stack))))
    component))

;;; ============================================================
;;; Strongly Connected Components
;;; ============================================================

(defun compute-sccs (graph nodes)
  "Compute strongly connected components using depth-first search."
  (let ((order
          (dfs-order graph nodes))
        (visited
          (make-hash-table :test #'eq))
        (components '()))
    (dolist (node order)
      (unless (gethash node visited)
        (push
         (dfs-component graph node visited)
         components)))
    (nreverse components)))