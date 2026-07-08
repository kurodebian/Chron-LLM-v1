;;;; world.lisp
;;;; Chron-LLM Δ3
;;;; World Service
;;;;
;;;; Responsibility
;;;;    - World (Lineage) management
;;;;    - Branch creation
;;;;    - World query
;;;;    - Synchronizing active conversation timelines with immutable WAL
;;;;
;;;; Non Responsibility
;;;;    - Runtime
;;;;    - Prompt
;;;;    - Immune
;;;;    - Graph Projection

(in-package :chron-llm)

;; ============================================================================
;; 1. Active Context Structures (Evolved from r0/history.lisp)
;; ============================================================================

(defstruct (world-timeline
             (:conc-name world-timeline-))
  "Encapsulates the active, mutable conversation timeline for a specific world-id.
   Any mutation via this structure automatically streams events down into the immutable WAL."
  (world-id 0 :type integer)
  (events   (make-array 0 :adjustable t :fill-pointer 0) :type vector))

;; ============================================================================
;; 2. World Allocation
;; ============================================================================

(defun allocate-world-id (wal)
  "新しい世界線IDを払い出す。"
  (incf (wal-world-counter wal)))

;; ============================================================================
;; 3. Branch & Lifecycle Evolution
;; ============================================================================

(defun stage-branch-world (graph wal parent-world-id)
  "親世界線から新しい世界線を作成し、Branch EventをStageする。"
  (let* ((new-world-id
          (allocate-world-id wal))

         (parent-node
          (get-latest-node-in-world
           graph
           parent-world-id))

         (parent-node-id
          (if parent-node
              (causal-node-id parent-node)
              0)))

    (stage-event
     wal
     :branch
     new-world-id
     (list
      :parent-world parent-world-id
      :parent-node parent-node-id))

    new-world-id))

(defun world-timeline-branch (graph wal parent-timeline)
  "親世界線のタイムラインをフォークし、因果グラフとWALに新しい世界線を刻みつつ、
   複製された新しい歴史を持つ 'world-timeline' 構造体を生成して返す。
   エージェントが新しい思考の選択肢（世界線）を分岐探索する核心のプリミティブ。"
  (let* ((parent-id (world-timeline-world-id parent-timeline))
         (new-id    (stage-branch-world graph wal parent-id)))
    (make-world-timeline
     :world-id new-id
     :events   (copy-seq (world-timeline-events parent-timeline)))))

;; ============================================================================
;; 4. Timeline Mutation & WAL Synchronization
;; ============================================================================

(defun world-timeline-append (wal timeline role content)
  "タイムラインに新しい対話イベント（history-event）を追加する。
   同時に、下層の不変ログ（WAL）へ自動的に :chat イベントを Stage して永続化する。"
  ;; A. メモリ上のコンテキストバッファへ追加 (types.lisp の共通型を使用)
  (let ((ev (make-history-event :role role :content content)))
    (vector-push-extend ev (world-timeline-events timeline)))
  
  ;; B. カーネル不変ログ（WAL）へのトランザクション発行
  (stage-event
   wal
   :chat
   (world-timeline-world-id timeline)
   (list :role role :content content))
  timeline)

(defun world-timeline-size (timeline)
  "タイムラインに格納されている現在の対話イベント数を返す。"
  (length (world-timeline-events timeline)))

;; ============================================================================
;; 5. World Query
;; ============================================================================

(defun world-exists-p (graph world-id)
  (not
   (null
    (get-latest-node-in-world
     graph
     world-id))))

(defun latest-node-in-world (graph world-id)
  (get-latest-node-in-world
   graph
   world-id))

(defun world-parent-node (graph world-id)
  (let ((node
         (latest-node-in-world
          graph
          world-id)))

    (when node

      (let ((parent-id
             (get-parent-node-id
              graph
              (causal-node-id node))))

        (and parent-id
             (gethash
              parent-id
              (causal-graph-nodes graph)))))))