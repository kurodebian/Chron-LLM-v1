;;;; session.lisp
;;;; Chron-LLM v1
;;;; LLM Session State

(in-package :chron-llm)

(defparameter *n-past* 0)
(declaim (special *n-past*))

(defun reset-session ()
  (setf *n-past* 0))

(defun session-n-past ()
  *n-past*)

(defun (setf session-n-past) (value)
  (setf *n-past* value))