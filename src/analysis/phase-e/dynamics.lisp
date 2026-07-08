;;;; dynamics.lisp
;;;; Chron-LLM v1
;;;; Analysis Layer (Phase E) - Causal & Graph Dynamics
;;;;
;;;; Responsibility
;;;;    - Microscopic trial divergence profiling (p-same metrics)
;;;;    - Macroscopic graph attractor and rollout simulation
;;;;
;;;; Non Responsibility
;;;;    - CFFI Low-level registry mapping (LLM responsibility)
;;;;    - Modifying active world topologies (Kernel responsibility)

(in-package :chron-llm)

;;; ============================================================
;;; 1. Microscopic Trial Dynamics (Merged from ir/divergence.lisp)
;;; ============================================================

(defun extract-actions (stream)
  "Extracts evaluation-phase tokens from the raw IR stream, sorted by position."
  (let ((sorted (sort (copy-seq stream) #'< :key #'ir-pos)))
    (loop for ir across sorted
          when (= (ir-phase ir) 1)
            collect ir)))

(defun run-ir-trial (prompt)
  "Clears native token buffer, triggers FFI generation, and returns high-res action vector."
  ;; llama-engine.lisp 側のインメモリ高速駆動版をダイレクトに叩き、*ir-stream* を回収
  (llama-run prompt)
  (coerce (extract-actions *ir-stream*) 'vector))

(defun divergence-profile (prompt n-runs)
  "Profiles the chaotic divergence of the agent across N separate trials.
   Returns step-by-step token stability metrics (p-same) to gauge agent hesitation."
  (let* ((runs (loop repeat n-runs collect (run-ir-trial prompt)))
         (max-len (apply #'min (mapcar #'length runs))))
    (loop for step from 0 below max-len
          for tokens-at-t =
            (mapcar (lambda (seq) (ir-token (aref seq step))) runs)
          for all-same = (apply #'= tokens-at-t)
          collect (list :t step
                        :all-same all-same
                        :p-same (/ (count (car tokens-at-t) tokens-at-t)
                                   (length tokens-at-t))))))

;;; ============================================================
;;; 2. Macroscopic Graph Dynamics (Deterministic Attractor Search)
;;; ============================================================

(defun next-event (graph node-id)
  "Return the strongest outgoing causal transition edge from NODE-ID."
  (let ((edges
          (remove-if-not
           (lambda (e)
             (eq (edge-from e) node-id))
           (graph-edges graph))))
    (first
     (sort edges
           #'>
           :key #'edge-strength))))

(defun rollout* (graph start steps)
  "Deterministically rollout the causal transition graph for STEPS transitions."
  (let ((node start)
        (path (list start)))
    (dotimes (_ steps)
      (declare (ignore _))
      (let ((edge (next-event graph node)))
        (unless edge
          (return))
        (setf node (edge-to edge))
        (push node path)))
    (nreverse path)))

(defun find-attractor (graph start steps)
  "Simulates macro-dynamics and returns the final observed attractor node (Lock-in check)."
  (first
   (last
    (rollout* graph start steps))))