;;; myhistory.el --- show searched word by helm

;; Copyright (C) 2013 by Yuta Yamada

;; Author: Yuta Yamada <cokesboy"at"gmail.com>

;;; License:
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;; Commentary:

;;; Code:

(eval-when-compile (require 'cl))
(require 'lookup)
(require 'helm)
(defvar myhistory-dir "~/.myhistory")
(defvar myhistory-histfile        (format "%s/%s" myhistory-dir "history"))
(defvar myhistory-remembered-file (format "%s/%s" myhistory-dir "remembered"))
(defvar myhistory-search-history nil)
(defvar myhistory-remembered-words nil)

(defadvice lookup-pattern
  (around ad-push-searched-word activate)
  "Add history to `myhistory-search-history."
  (when (or (null myhistory-search-history)
            (not (member (ad-get-arg 0) myhistory-search-history)))
    (push
     (downcase (format (substring-no-properties (ad-get-arg 0))))
     myhistory-search-history))
  ad-do-it)

(defun my/helm-lookup-history ()
  "Lookup lookup.el's search history by helm."
  (interactive)
  (helm
   :sources
   '(((name . "helm-lookup-histories")
      (candidates . myhistory-search-history)
      (action .
              (("Lookup" .
                (lambda (line) (lookup-pattern line)))
               ("Remembered" .
                (lambda (word)
                  (push (format word) myhistory-remembered-words)
                  (myhistory-delete-history)))))))))

(defun myhistory-save-history ()
  "Save lookup.el's searched history to myhistory-histfile."
  (when myhistory-search-history
    (save-current-buffer
      (with-temp-buffer
        (insert (format "%s" myhistory-search-history))
        (write-file myhistory-histfile)))))

(defun myhistory-save-remembered-words ()
  (when myhistory-remembered-words
    (save-current-buffer
      (with-temp-buffer
        (insert (format "%s" myhistory-remembered-words))
        (write-file myhistory-remembered-file)))))

(defun myhistory-set (file var &optional force)
  "WIP."
  (when (and (file-exists-p file)
             (or (null (symbol-value var))
                 force))
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (insert (format "(setq %s '" (symbol-name var)))
      (goto-char (point-max))
      (insert " )")
      (eval-buffer))))

(defun myhistory-delete-history ()
  (interactive)
  (setq myhistory-search-history
        (loop for hist in myhistory-search-history
              unless (member hist myhistory-remembered-words)
              collect hist)))

(myhistory-set myhistory-histfile        'myhistory-search-history)
(myhistory-set myhistory-remembered-file 'myhistory-remembered-words)

;; save history when quit Emacs
(add-hook 'kill-emacs-hook
          '(lambda ()
             (myhistory-delete-history)
             (myhistory-save-history)
             (myhistory-save-remembered-words)))

(provide 'myhistory)

;; Local Variables:
;; coding: utf-8
;; mode: emacs-lisp
;; End:

;;; myhistory.el ends here
