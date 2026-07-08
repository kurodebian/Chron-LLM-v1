;;;; runtime.lisp
;;;; Chron-LLM v1
;;;; Runtime Layer (Pure Interaction & Orchestration)

(in-package :chron-llm.runtime)


;;; ============================================================
;;; High-Level Turn Orchestration
;;; ============================================================

(defun execute-runtime-turn
    (kernel model-path user-input)

  "Orchestrates a single discrete cognitive turn of the agent."

  ;; User -> Kernel Transaction

  (kernel-submit-user-input
   kernel
   user-input)


  (let* ((state
           (kernel-current-state kernel))

         (context
           (kernel-state-context state)))


    (format t
            "~&[World ID: ~D]  [Causal Health: ~A]~%"
            (kernel-state-world-id state)
            (kernel-state-health state))


    ;; Phase-B projection

    (let ((prompt
            (project-to-prompt context)))


      ;; LLM generation

      (run-llm-generation
       kernel
       model-path
       prompt)))


  ;; Assistant output extraction

  (let* ((updated-state
           (kernel-current-state kernel))

         (updated-context
           (kernel-state-context updated-state))

         (latest-event
           (view-last updated-context)))


    (when (and latest-event
               (eq (history-event-role latest-event)
                   :assistant))


      (format t
              "~&AI> ~A~%"
              (history-event-content latest-event))

      (finish-output)))


  kernel)



;;; ============================================================
;;; Core Agent Main Loop
;;; ============================================================

(defun agent-main-loop
    (model-path)

  "Initializes the Chron-LLM kernel and starts console interaction."


  (format t
          "~&====================================================~%")

  (format t
          "~&   Chron-LLM v1 Alpha - Persistent Agent REPL       ~%")

  (format t
          "~&====================================================~%")


  (finish-output)


  (let ((kernel
          (make-chron-kernel)))


    (loop

      (format t "~&User> ")

      (finish-output)


      (let ((input
              (read-line *standard-input* nil :exit)))


        ;; exit handling

        (when (or (null input)
                  (eq input :exit)
                  (string= input ":quit"))

          (format t
                  "~&Exiting Chron-LLM runtime system. Goodbye.~%")

          (return))


        ;; ignore empty input

        (unless (string= input "")


          (handler-case

              (execute-runtime-turn
               kernel
               model-path
               input)


            (error (e)

              (format t
                      "~&[Runtime Error Captured] ~A~%"
                      e)

              (finish-output)))))))


  t)