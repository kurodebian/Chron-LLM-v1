;;;; event.lisp
;;;; Chron-LLM v1
;;;; Analysis Layer (Phase A) - Event Construction
;;;;
;;;; Responsibility
;;;;    - Pure structural event atom definition for the analysis pipeline
;;;;    - Event equality verification
;;;;
;;;; Non Responsibility
;;;;    - WAL / Causal tracking (Kernel responsibility)
;;;;    - Mutable state or stream management (LLM / Kernel responsibility)

(defpackage :phase-a.event
  (:use :cl)
  (:export
   #:make-event
   #:event-p
   #:event-type
   #:event-payload
   #:event-equal))

(in-package :phase-a.event)

;;; ============================================================
;;; Phase A Event Structure (Upgraded & Collision-Free)
;;; ============================================================

(defstruct (phase-a-event
             (:constructor make-event (type payload))
             (:conc-name event-)
             (:predicate event-p))
  "Analysis-specific event atom. Encapsulates semantic types and telemetry payloads.
   Functions like make-event, event-type, and event-p are preserved with 100% backward compatibility."
  type
  payload)

;;; ============================================================
;;; Structural Equality
;;; ============================================================

(defun event-equal (a b)
  "Phase A structural equality for analysis events."
  (and (event-p a)
       (event-p b)
       (equal (event-type a) (event-type b))
       (equal (event-payload a) (event-payload b))))