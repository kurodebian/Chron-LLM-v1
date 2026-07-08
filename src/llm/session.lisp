;;;; session.lisp
;;;; Chron-LLM v1
;;;; LLM Session State

(in-package :chron-llm.llm)

;; 統合されたエンジン空間から、状態管理APIを公開
(export '(*n-past*
          reset-session
          session-n-past))

(defparameter *n-past* 0)
(declaim (special *n-past*))

(defun reset-session ()
  (setf *n-past* 0))

(defun session-n-past ()
  *n-past*)

(defun (setf session-n-past) (value)
  (setf *n-past* value))