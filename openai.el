;;;; OpenAI interactive mode
(require 'url)

;; Create window to dipslay responses
(defun my-api-response-buffer ()
  (switch-to-buffer-other-window "**")
  (erase-buffer)
  (other-window 1))


(defun my-send-buffer-to-chatgpt (&optional text)
  (interactive)
  (message "Sending buffer content to ChatGPT...")
  (unless text (setq text (buffer-string)))
  (let* ((api-key (getenv "OPENAI_API_KEY"))
         (buffer-content text)
         (url-request-method "POST")
         (url-request-extra-headers `(("Content-Type" . "application/json")
                                      ("Authorization" . ,(format "Bearer %s" api-key))))
	 (json-data (json-encode `(("model" . "gpt-3.5-turbo")
                                          ("messages" . 
                                           ((("role" . "system")
                                             ("content" . "You are programming assistant that write simple programs in emacs lisp"))
					    (("role" . "system")
                                             ("content" . "Only return the elisp code and not other content around it. No instructions or decorators"))
                                            (("role" . "user")
                                             ("content" . ,text)))))))
         (url-request-data (encode-coding-string json-data 'utf-8))
         (url "https://api.openai.com/v1/chat/completions"))
    (url-retrieve url #'my-handle-api-response (list (current-buffer)))))


(require 'json)

(defun my-handle-api-response (status &optional original-buffer)
  "Handle the API response. STATUS is the network status."
  (unless (search-forward "\n\n" nil t) ; Move to the end of headers, or skip if not found.
    (error "End of headers not found"))
  (let* ((json-object-type 'hash-table)
         (json-array-type 'list)
         (json-false nil)
         (json-response (json-read)) ; Parse JSON from current position.
         (choices (gethash "choices" json-response))
         (first-choice (car choices)) ; Assuming there's at least one choice.
         (message (gethash "message" first-choice))
         (content (gethash "content" message)))
    (when original-buffer
      (with-current-buffer original-buffer
	(unless (bolp) ; Check if the point is at the beginning of a line.
          (insert "\n")) ; If not, insert a new line first.
	(insert content)
	(deactivate-mark)
        (goto-char (point-max))))))


(defun my-send-region-to-chatgpt ()
  (interactive)
  (if (use-region-p)
      (let ((region-text (buffer-substring-no-properties (region-beginning) (region-end))))
        (my-send-buffer-to-chatgpt region-text))
    (message "No region selected!")))

(global-set-key (kbd "C-c C-a") 'my-send-buffer-to-chatgpt)
(global-set-key (kbd "C-c C-r") 'my-send-region-to-chatgpt)
