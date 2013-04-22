;;; golden-ratio.el --- Automatic resizing of Emacs windows to the golden ratio

;; Copyright (C) 2012 Roman Gonzalez

;; Author: Roman Gonzalez <romanandreg@gmail.com>
;; Mantainer: Roman Gonzalez <romanandreg@gmail.com>
;; Created: 13 Oct 2012
;; Keywords: Window Resizing
;; Version: 0.0.4

;; Code inspired by ideas from Tatsuhiro Ujihisa

;; This file is not part of GNU Emacs.

;; This file is free software (MIT License)

;;; Code:
(eval-when-compile (require 'cl))

(defconst golden-ratio--value 1.618
  "The golden ratio value itself.")

(defgroup golden-ratio nil
  "Resize windows to golden ratio."
  :group 'windows)

;; Major modes that are exempt from being resized. An example of this
;; for users of Org-mode might be:
;;  ("calendar-mode")
(defcustom golden-ratio-exclude-modes nil
  "An array of strings naming major modes.
Switching to a buffer whose major mode is a member of this list
will not cause the window to be resized to the golden ratio."
  :type '(repeat string)
  :group 'golden-ratio)

;; Buffer names that are exempt from being resized. An example of this
;; for users of Org-mode might be (note the leading spaces):
;;  (" *Org tags*" " *Org todo*")
(defcustom golden-ratio-exclude-buffer-names nil
  "An array of strings containing buffer names.
Switching to a buffer whose name is a member of this list
will not cause the window to be resized to the golden ratio."
  :type '(repeat string)
  :group 'golden-ratio)

(defcustom golden-ratio-inhibit-functions nil
  "List of functions to call with no arguments.
Switching to a buffer, if any of these functions returns non-nil
will not cause the window to be resized to the golden ratio."
  :group 'golden-ratio
  :type '(repeat symbol))

(defcustom golden-ratio-extra-commands
  '(windmove-left windmove-right windmove-down windmove-up)
  "List of extra commands used to jump to other window."
  :group 'golden-ratio
  :type '(repeat symbol))
  
;;; Compatibility
;;
(unless (fboundp 'window-resizable-p)
  (defalias 'window-resizable-p 'window--resizable-p))

(defun golden-ratio--dimensions ()
  (list (floor (/ (frame-height) golden-ratio--value))
        (floor (/ (frame-width)  golden-ratio--value))))

(defun golden-ratio--resize-window (dimensions &optional window)
  (with-selected-window (or window (selected-window))
    (let ((nrow  (floor (- (first  dimensions)
                           (golden-ratio--window-height-after-balance))))
          (ncol  (floor (- (second dimensions)
                           (golden-ratio--window-width-after-balance)))))
      (when (window-resizable-p (selected-window) nrow)
        (enlarge-window nrow))
      (when (window-resizable-p (selected-window) ncol t)
        (enlarge-window ncol t)))))

(defun golden-ratio--window-width-after-balance ()
  (let* ((size-ls (loop for i in (window-list)
                        unless (window-full-width-p i)
                        collect (window-width i)))
         (len (length size-ls))
         (width (and size-ls (floor (/ (apply #'+ size-ls) len)))))
    (if width (min (window-width) width) (window-width))))

(defun golden-ratio--window-height-after-balance ()
  (let* ((size-ls (loop for i in (window-list)
                        unless (or (window-full-height-p i)
                                   (not (window-full-width-p i)))
                        collect (window-height i)))
         (len (length size-ls))
         (height (and size-ls (floor (/ (apply #'+ size-ls) len)))))
    (if height (min (window-height) height) (window-height))))

;;;###autoload
(defun golden-ratio ()
  "Resizes current window to the golden-ratio's size specs."
  (interactive)
  (unless (or (window-minibuffer-p)
              (one-window-p)
              (member (symbol-name major-mode)
                      golden-ratio-exclude-modes)
              (member (buffer-name)
                      golden-ratio-exclude-buffer-names)
              (and golden-ratio-inhibit-functions
                   (loop for fun in golden-ratio-inhibit-functions
                         always (funcall fun))))
    (let ((dims (golden-ratio--dimensions)))
      (golden-ratio--resize-window dims)
      (scroll-left)
      (recenter))))

;; Should return nil
(defadvice other-window
    (after golden-ratio-resize-window)
  (golden-ratio) nil)

;; Should return the buffer
(defadvice pop-to-buffer
    (around golden-ratio-resize-window)
  (prog1 ad-do-it (golden-ratio)))

(defun golden-ratio--post-command-hook ()
  (when (or (memq this-command golden-ratio-extra-commands)
            (and (consp this-command)
                 (loop for com in golden-ratio-extra-commands
                       thereis (or (memq com this-command)
                                   (memq (car-safe com) this-command)))))
    (golden-ratio)))

;;;###autoload
(define-minor-mode golden-ratio-mode
    "Enable automatic window resizing with golden ratio."
  :lighter " Golden"
  :global t
  (if golden-ratio-mode
      (progn
        (add-hook 'window-configuration-change-hook 'golden-ratio)
        (add-hook 'post-command-hook 'golden-ratio--post-command-hook)
        (ad-activate 'other-window)
        (ad-activate 'pop-to-buffer))
      (remove-hook 'window-configuration-change-hook 'golden-ratio)
      (remove-hook 'post-command-hook 'golden-ratio--post-command-hook)
      (ad-deactivate 'other-window)
      (ad-activate 'pop-to-buffer)))


(provide 'golden-ratio)

;;; golden-ratio.el ends here
