;;; exwm-edit.el --- Edit mode for EXWM -*- lexical-binding: t; -*-
;;
;; Filename: exwm-edit.el
;; Description: Edit mode for EXWM.
;; Author: Ag Ibragimov
;; Maintainer: Ag Ibragimov (concat "agzam.ibragimov" "@" "gm" "ail" ".c" "om")
;; Copyright (C) 2018  Ag Ibragimov

;; Keywords: exwm edit
;; Version: 0.0.1

;;; Commentary:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Similar to atomic-chrome https://github.com/alpha22jp/atomic-chrome
;; except this package is made to work with EXWM
;; and works with any editable element of any app
;;
;; The idea is very simple - when you press the keybinding,
;; it simulates [C-a (select all) + C-x (cut)],
;; the opens a buffer and yanks the content - so you can edit it,
;; after you done - it grabs (now edited text) and pastes back to the original app
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Prerequisites:
;; in order for it to work properly, you're gonna need to install https://github.com/DamienCassou/gpastel
;;

(with-eval-after-load 'exwm
  (defvar exwm-edit--last-exwm-buffer nil
    "Last buffer that invoked `exwm-edit'.")

  (defun exwm-edit--finish ()
    (interactive)
    (mark-whole-buffer)
    (kill-region (region-beginning)
                 (region-end))
    (kill-buffer-and-window)
    (let ((buffer (switch-to-buffer exwm-edit--last-exwm-buffer)))
      (with-current-buffer buffer
        (exwm-input--set-focus (exwm--buffer->id (window-buffer (selected-window))))
        (exwm-input--fake-key ?\C-v)
        (setq exwm-edit--last-exwm-buffer nil))))

  (defun exwm-edit--cancel ()
    (interactive)
    (kill-buffer-and-window)
    (let ((buffer (switch-to-buffer exwm-edit--last-exwm-buffer)))
      (with-current-buffer buffer
        (exwm-input--set-focus (exwm--buffer->id (window-buffer (selected-window))))
        (exwm-input--fake-key ?\C-v)
        (setq exwm-edit--last-exwm-buffer nil))))

  (defvar exwm-edit-mode-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "C-c C-c") 'exwm-edit--finish)
      (define-key map (kbd "C-c C-k") 'exwm-edit--cancel)
      map)
    "Keymap for minor mode `exwm-edit-mode'.")

  (define-minor-mode exwm-edit-mode
    "Minor mode enabled in `exwm-edit--compose' buffer"
    :init-value nil
    :lighter " exwm-edit"
    :keymap exwm-edit-mode-map)

  (defun exwm-edit--buffer-title (str)
    (concat "*exwm-edit " str " *"))

  (defun exwm-edit--turn-on-edit-mode ()
    "Turn on `exwm-edit-mode' if the buffer was created by `exwm-edit--compose'"
    (when (string= (exwm-edit--buffer-title exwm-edit--last-exwm-buffer)
              (buffer-name (current-buffer)))
      (exwm-edit-mode t)))

  (define-global-minor-mode global-exwm-edit-mode
    exwm-edit-mode exwm-edit--turn-on-edit-mode)

  (defun exwm-edit--compose ()
    "Edit text in an EXWM app"
    (interactive)
    (let* ((title (exwm-edit--buffer-title (buffer-name)))
           (existing (get-buffer title))
           (inhibit-read-only t)
           (save-interprogram-paste-before-kill t)
           (yank-pop-change-selection t))
      (when (derived-mode-p 'exwm-mode)
        (setq exwm-edit--last-exwm-buffer (buffer-name))
        (if existing
            (switch-to-buffer-other-window existing)
          (progn
            (exwm-input--fake-key ?\C-a)
            (exwm-input--fake-key ?\C-x)
            (exwm-input--fake-key ?\C-\M-o)
            (let* ((buffer (get-buffer-create title)))
              (with-current-buffer buffer
                (text-mode)
                (spacemacs/toggle-visual-line-navigation-on)
                (insert (gpastel-get-copied-text))
                (evil-insert 1)
                (exwm-edit-mode 1)
                (switch-to-buffer-other-window buffer)
                (setq-local
                 header-line-format
                 (substitute-command-keys
                  "Edit, then exit with `\\[exwm-edit--finish]' or cancel with \ `\\[exwm-edit--cancel]'")))))))))

  (exwm-input-set-key (kbd "C-c '") #'exwm-edit--compose)
  (global-exwm-edit-mode 1))

(provide 'exwm-edit)
