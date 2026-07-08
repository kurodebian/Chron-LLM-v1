;;;; phi4-agent.lisp
;;;; Chron-LLM v1
;;;; Boot Entry

(in-package :chron-llm.agent)

;;; ============================================================
;;; Boot Entry
;;; ============================================================

(defparameter *default-model-path*
  "/path/to/model.gguf")


(defun start-delta3
    (&optional
      (model-path *default-model-path*))
  "Chron-LLM を起動する。"

  (format t "~%========================================~%")
  (format t "Chron-LLM Starting...~%")
  (format t "Model : ~A~%" model-path)
  (format t "========================================~%")

  ;; Runtime Layer がモデル初期化と REPL 制御を担当
  (agent-main-loop model-path))


(defun start-delta3-stub ()
  "スタブ環境で Runtime を起動する。"

  (format t "~%========================================~%")
  (format t "Chron-LLM Stub Starting...~%")
  (format t "========================================~%")

  ;; モデルなしで Runtime 起動
  (agent-main-loop nil))