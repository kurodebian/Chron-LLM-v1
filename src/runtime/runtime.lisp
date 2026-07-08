;;;; runtime.lisp
;;;; Chron-LLM v1
;;;; Runtime Layer (Pure Interaction & Orchestration)
;;;;
;;;; Responsibility
;;;;    - Console I/O and user text streaming
;;;;    - Top-level Runtime Loop orchestration
;;;;    - Invoking state projections (Phase B Prompt Builder)
;;;;    - Executing LLM orchestration via Kernel transaction
;;;;
;;;; Non Responsibility
;;;;    - WAL / Mutation recording (Kernel responsibility)
;;;;    - Graph topology / Causal indexing (Kernel responsibility)
;;;;    - Low-level CFFI callbacks (LLM responsibility)
;;;;    - Maintaining history state buffers (Stateless abstraction)

(in-package :chron-llm)

;;; ============================================================
;;; High-Level Turn Orchestration (Evolved from r0/chat)
;;; ============================================================

(defun execute-runtime-turn (kernel model-path user-input)
  "Orchestrates a single discrete cognitive turn of the agent.
   Transforms synchronous user text into immutable causal events."
  
  ;; 1. User -> Kernel Transaction (WAL logging & Graph indexing occur inside)
  (kernel-submit-user-input kernel user-input)

  (let* ((state   (kernel-current-state kernel))
         (context (kernel-state-context state)))

    ;; 2. UI Diagnostics View (Visualizes multi-world metadata)
    (format t "~&[World ID: ~D]  [Causal Health: ~A]~%"
            (kernel-state-world-id state)
            (kernel-state-health state))

    ;; 3. State Projection (Phase B View: Projects timeline history into raw prompt string)
    (let ((prompt (project-to-prompt context)))

      ;; 4. LLM Invocation & Assistant Event Ingestion
      ;;    Triggers in-memory FFI generation loop, implicitly recording raw IR stream
      (run-llm-generation kernel model-path prompt)))

  ;; 5. UI Output Extraction & Trace Verification
  (let* ((updated-state   (kernel-current-state kernel))
         (updated-context (kernel-state-context updated-state))
         ;; phase-b/view.lisp で定義した不変履歴の末尾抽出 API を使用
         (latest-event    (view-last updated-context)))
    
    (when (and latest-event (eq (history-event-role latest-event) :assistant))
      (format t "~&AI> ~A~%" (history-event-content latest-event))
      (finish-output)))
  
  kernel)

;;; ============================================================
;;; Core Agent Main Loop (Evolved from r0/start-chat)
;;; ============================================================

(defun agent-main-loop (model-path)
  "Initializes the stateless multi-world kernel and drives the console I/O loop."
  (format t "~&====================================================~%")
  (format t "~&   Chron-LLM v1 Alpha - Persistent Agent REPL       ~%")
  (format t "~&====================================================~%")
  (finish-output)

  (let ((kernel (make-chron-kernel)))
    (loop
      (format t "~&User> ")
      (finish-output)

      (let ((input (read-line *standard-input* nil :exit)))
        ;; 終了コマンドまたはストリーム切断時の安全な脱出
        (when (or (null input) (eq input :exit) (string= input ":quit"))
          (format t "~&Exiting Chron-LLM runtime system. Goodbye.~%")
          (return))

        ;; 空入力のスキップガード
        (unless (string= input "")
          (handler-case
              (execute-runtime-turn kernel model-path input)
            
            (error (e)
              (format t "~&[Runtime Error Captured] ~A~%" e)
              (finish-output)))))))
  
  t)