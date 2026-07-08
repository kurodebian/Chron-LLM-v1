;;;; cycle.lisp
;;;; Chron-LLM Experiments
;;;; Causal Dynamics
;;;; Cycle Analysis

(in-package :experiment)

;;; ============================================================
;;; Cycle Detection
;;; ============================================================

(defun extract-cycle-from-path (path)
  "Extract the last observed recurrent cycle from a rollout path."

  (when (endp path)
    (return-from extract-cycle-from-path nil))

  (let* ((rev (reverse path))
         (last-node (first rev))
         (pos (position last-node
                        (rest rev))))

    (if pos
        ;; suffix beginning at the first recurrence
        (subseq rev 0 (1+ pos))

        ;; no recurrence observed
        (list last-node))))

(defun find-recurrent-cycle (graph start steps)
  "Run a rollout and return the observed recurrent cycle."

  (extract-cycle-from-path
   (rollout* graph start steps)))