;;;; generation.lisp
;;;; Chron-LLM v1
;;;; Runtime Generation Boundary
;;;;
;;;; Responsibility:
;;;;   - Runtime generation boundary
;;;;   - Invoke LLM backend (future)
;;;;   - Commit assistant reply to Kernel
;;;;
;;;; Stub:
;;;;   Returns a fixed assistant response until llama.cpp is connected.

(in-package :chron-llm.runtime)

(defun run-llm-generation (kernel model-path prompt)
  (declare (ignore model-path prompt))

  ;; Stub implementation.
  ;; This will later become:
  ;;   reply <- chron-llm.llm:llm-generate-text(...)
  ;;   kernel-submit-assistant-reply(kernel, reply)

  (chron-llm.kernel:kernel-submit-assistant-reply
   kernel
   "[stub response]"))