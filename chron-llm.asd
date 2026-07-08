(asdf:defsystem "chron-llm"
  :version "1.0.0"
  :author "Junu"
  :license "MIT"
  :description "Causal Analysis Pipeline & Multi-World Execution Engine for Persistent AI Agent"
  :depends-on (:cffi :uiop)
  :serial t

  :components
  (
   ;; ------------------------------------------------------------
   ;; package.lisp
   ;; ------------------------------------------------------------
   (:file "package")

   ;; ------------------------------------------------------------
   ;; src/
   ;; ------------------------------------------------------------
   (:module "src"
    :serial t
    :components
    (

     ;; common/
     (:module "common"
      :serial t
      :components
      ((:file "types")))

     ;; llm/
     (:module "llm"
      :serial t
      :components
      ((:file "ffi-bindings")
       (:file "llama-engine")
       (:file "context")
       (:file "session")
       (:file "generate")))

     ;; kernel/
     (:module "kernel"
      :serial t
      :components
      ((:file "world")
       (:file "causal")
       (:file "graph")
       (:file "immune")
       (:file "kernel")))

     ;; analysis/
     (:module "analysis"
      :serial t
      :components
      (

       ;; phase-a/
       (:module "phase-a"
        :serial t
        :components
        ((:file "event")
         (:file "history")
         (:file "serializer")))

       ;; phase-b/
       (:module "phase-b"
        :serial t
        :components
        ((:file "view")))

       ;; phase-c/
       (:module "phase-c"
        :serial t
        :components
        ((:file "event-abi")
         (:file "justification")
         (:file "model")
         (:file "projection")))

       ;; phase-d/
       (:module "phase-d"
        :serial t
        :components
        ((:file "node")
         (:file "edge")
         (:file "graph")
         (:file "rules")
         (:file "builder")
         (:file "inference")
         (:file "rollout")
         (:file "trace")))

       ;; phase-e/
       (:module "phase-e"
        :serial t
        :components
        ((:file "scc")
         (:file "dynamics")
         (:file "cycle")
         (:file "basin")
         (:file "analyze")))))

     ;; runtime/
     (:module "runtime"
      :serial t
      :components
      ((:file "runtime")))))

   ;; ------------------------------------------------------------
   ;; agent/
   ;; ------------------------------------------------------------
   (:module "agent"
    :serial t
    :components
    ((:file "phi4-agent")))
   ))


;;; ------------------------------------------------------------
;;; Test System
;;; ------------------------------------------------------------

(asdf:defsystem "chron-llm/tests"
  :depends-on ("chron-llm")
  :serial t

  :components
  (
   (:module "tests"
    :serial t
    :components
    (

     (:module "kernel"
      :serial t
      :components
      ((:file "run-test")))

     (:module "analysis"
      :serial t
      :components
      ((:file "history-test")
       (:file "serializer-test")
       (:file "view-test")
       (:file "projection-test")
       (:file "edge-test")))))))
