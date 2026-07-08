(defpackage :chron-llm.common
  (:use :cl)
  (:export :ir :make-ir :ir-ctx-id :ir-pos :ir-phase :ir-token :ir-score
           :history-event :make-history-event :history-event-role :history-event-content))

(defpackage :chron-llm.llm
  (:use :cl :cffi :chron-llm.common)
  (:export :load-model :init-context :llama-run :init-ir-bridge
           :*model* :*ctx* :*ir-stream* :push-ir :clear-ir-stream))

(defpackage :chron-llm.kernel
  (:use :cl :chron-llm.common :chron-llm.llm)
  (:export :history :make-history :history-events :history-append :history-size :history-copy))

(defpackage :chron-llm.analysis
  (:use :cl :chron-llm.common :chron-llm.llm :chron-llm.kernel)
  (:export :project-to-prompt :divergence-profile :log-trace :save-trace-to-file))

(defpackage :chron-llm.runtime
  (:use :cl :chron-llm.llm :chron-llm.kernel :chron-llm.analysis)
  (:export :start-chat))