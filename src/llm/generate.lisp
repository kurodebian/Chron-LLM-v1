;;;; generate.lisp
;;;; Chron-LLM v1
;;;; LLM Generation Layer
;;;;
;;;; Responsibility:
;;;;   - Model Initialization
;;;;   - Prompt Prefill
;;;;   - Sampling
;;;;   - Decode
;;;;   - Text Generation
;;;;
;;;; Non Responsibility:
;;;;   - Kernel Commit
;;;;   - WAL
;;;;   - Graph
;;;;   - World
;;;;   - Immune
;;;;   - History

(in-package :chron-llm.llm)

(defun llm-generate-text
    (model-path
     prompt
     &key
       (max-tokens 256)
       (temperature 0.7)
       (top-p 0.9))

  (let ((model nil)
        (ctx nil)
        (sampler nil)
        (reply ""))

    (unwind-protect
         (progn
           ;; --------------------------------------------------
           ;; Initialize
           ;; --------------------------------------------------
           (multiple-value-bind (m c)
               (init-chron-llm model-path)
             (setf model m
                   ctx c))

           ;; --------------------------------------------------
           ;; Prefill
           ;; --------------------------------------------------
           (setf *n-past* 0)

           (prefill-prompt
            ctx
            (tokenize model prompt))

           ;; --------------------------------------------------
           ;; Sampler
           ;; --------------------------------------------------
           (setf sampler
                 (my-sampler-init
                  (float temperature 1.0f0)
                  (float top-p 1.0f0)))

           ;; --------------------------------------------------
           ;; Generation Loop
           ;; --------------------------------------------------
           (dotimes (step max-tokens)
             (declare (ignore step))

             (let ((token-id
                    (my-sampler-sample sampler ctx)))

               ;; EOS
               (when (my-llama-is-eog ctx token-id)
                 (return))

               ;; Decode
               (cffi:with-foreign-pointer (buf 256)
                 (let ((len
                        (my-llama-token-to-piece
                         model
                         token-id
                         buf
                         256)))
                   (when (> len 0)
                     (let ((piece
                            (cffi:foreign-string-to-lisp
                             buf
                             :count len)))
                       (format t "~A" piece)
                       (finish-output)
                       (setf reply
                             (concatenate
                              'string
                              reply
                              piece))))))

               ;; Eval
               (cffi:with-foreign-object (arr :int32 1)
                 (setf (cffi:mem-ref arr :int32 0)
                       token-id)

                 (unless
                     (zerop
                      (my-llama-eval
                       ctx
                       arr
                       1
                       *n-past*))
                   (error "Decode failed."))

                 (incf *n-past*))))

           ;; --------------------------------------------------
           ;; Return Generated Text
           ;; --------------------------------------------------
           reply)

      ;; ------------------------------------------------------
      ;; Cleanup
      ;; ------------------------------------------------------
      (when sampler
        (my-sampler-free sampler))

      (when ctx
        (my-llama-free ctx))

      (when model
        (my-llama-model-free model)))))
