(register-groups-bind () nil) ;; 処理系保護用

(defsystem "chron-llm"
  :version "1.0.0"
  :author "Junu"
  :license "MIT"
  :description "Causal Analysis Pipeline & Multi-World Execution Engine for Persistent AI Agent"
  :depends-on (:cffi :uiop)
  :serial t
  :components
  ((:file "package")
   (:module "src"
    :components
    ((:module "common"
      :components
      ((:file "types")))

     ;; 1. 物理層 (LLM Interaction)
     (:module "llm"
      :depends-on ("common")
      :serial t
      :components
      ((:file "ffi-bindings")
       (:file "llama-engine")
       (:file "context")
       (:file "session")
       (:file "generate")))

     ;; 2. 実行層 (World State Sandbox)
     (:module "kernel"
      :depends-on ("common" "llm")
      :components
      ((:file "world")
       (:file "causal")
       (:file "graph")
       (:file "immune")
       (:file "kernel" :depends-on ("world" "causal" "graph" "immune"))))

     ;; 3. 解析層 (Causal & Dynamical Analysis)
     (:module "analysis"
      :depends-on ("common" "kernel")
      :components
      ((:module "phase-a"
        :serial t
        :components
        ((:file "event")
         (:file "history")
         (:file "serializer")))
       (:module "phase-b"
        :depends-on ("phase-a")
        :components
        ((:file "view")))
       (:module "phase-c"
        :depends-on ("phase-b")
        :serial t
        :components
        ((:file "event-abi")
         (:file "justification")
         (:file "model")
         (:file "projection")))
       (:module "phase-d"
        :depends-on ("phase-c")
        :components
        ((:file "node")
         (:file "edge")
         (:file "graph"     :depends-on ("node" "edge"))
         (:file "rules"     :depends-on ("graph"))
         (:file "builder"   :depends-on ("graph" "rules"))
         (:file "inference" :depends-on ("builder"))
         (:file "rollout"   :depends-on ("inference"))
         (:file "trace"     :depends-on ("rollout"))))
       (:module "phase-e"
        :depends-on ("phase-d")
        :components
        ((:file "scc")
         (:file "cycle")
         (:file "basin")
         (:file "dynamics")
         (:file "analyze" :depends-on ("scc" "cycle" "basin" "dynamics"))))))

     ;; 4. 対話層 (Pure REPL Interface)
     (:module "runtime"
      :depends-on ("llm" "kernel" "analysis")
      :components
      ((:file "runtime")))))

   ;; 5. 最上位アプリケーション (Agent)
   (:module "agent"
    :depends-on ("src")
    :components
    ((:file "phi4-agent")))))

;;; テスト用サブシステムの定義
(defsystem "chron-llm/tests"
  :depends-on ("chron-llm")
  :serial t
  :components
  ((:module "tests"
    :components
    ((:module "kernel"
      :components
      ((:file "run-test")))
     (:module "analysis"
      :components
      ((:file "history-test")
       (:file "serializer-test")
       (:file "view-test")
       (:file "projection-test")
       (:file "edge-test")))))))