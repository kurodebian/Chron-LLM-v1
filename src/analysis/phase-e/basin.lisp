;;;; basin.lisp
;;;; Chron-LLM Experiments
;;;; Basin Analysis

(defpackage :phase-e.basin
  (:use :cl
        :phase-e.dynamics)
  (:export #:build-basin-map
           #:basin
           #:make-basin
           #:basin-attractor
           #:basin-nodes
           #:basin-mass
           #:basin-ratio
           #:build-basin-structure))

(in-package :phase-e.basin)

;;; ============================================================
;;; Basin Map
;;; ============================================================

(defun build-basin-map (graph nodes steps)
  "Map each node to its observed attractor."
  (let ((table (make-hash-table :test #'eq)))
    (dolist (node nodes)
      (let ((attractor
             (find-attractor
              graph
              node
              steps)))
        (push node
              (gethash attractor table))))
    table))

;;; ============================================================
;;; Basin Structure
;;; ============================================================

(defstruct basin
  attractor
  nodes
  mass
  ratio)

(defun build-basin-structure (basin-map total-nodes)
  "Convert a basin map into observational basin statistics."
  (let ((result '()))
    (maphash
     (lambda (attractor nodes)
       (let* ((mass (length nodes))
              (ratio (if (zerop total-nodes)
                         0.0
                         (/ (float mass)
                            total-nodes))))
         (push
          (make-basin
           :attractor attractor
           :nodes nodes
           :mass mass
           :ratio ratio)
          result)))
     basin-map)
    (nreverse result)))