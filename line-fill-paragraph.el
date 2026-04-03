;;; line-fill-paragraph.el --- Functions for working with verilog files -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023-2026 Andrew Peck

;; Author: Andrew Peck <peckandrew@gmail.com>
;; URL: https://github.com/andrewpeck/line-fill-paragraph
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; Keywords: writing

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>

;;; Commentary:
;;
;;; Code:

(defvar line-fill-paragraph-non-separators
  (append
   (list "n.b." "i.e." "e.g." "c.f." "viz." "eg." "ie.")
   ;; single letter initials such as A. B. C.
   (mapcar (lambda (x) (concat (upcase (char-to-string x)) ".")) (number-sequence ?a ?z))))

;;;###autoload
(defun line-fill-paragraph (&optional P)
  "When called with prefix argument P call `fill-paragraph'.
Otherwise split the current paragraph into one sentence per line."
  (interactive "P")
  ;; ordinary fill paragraph when prefix arg is set
  (if P (fill-paragraph P)
    (let ((abbrev-regexp
           (concat "\\s-+\\("
                   (string-join (mapcar #'regexp-quote line-fill-paragraph-non-separators) "\\|")
                   "\\)"))
          (paren-end-regexp "[!?][\"')]+\\'"))
      (save-excursion
        (let ((fill-column 12345678)) ;; relies on dynamic binding
          (fill-paragraph) ;; this will not work correctly if the paragraph is
          ;; longer than 12345678 characters (in which case the
          ;; file must be at least 12MB long. This is unlikely.)
          (let ((end (save-excursion
                       (forward-paragraph 1)
                       (backward-sentence)
                       (point-marker)))) ;; remember where to stop
            (beginning-of-line)
            (catch 'line-fill-paragraph-done
              (while t
                ;; advance one sentence; exit cleanly at end of buffer or past end
                (condition-case nil
                    (forward-sentence)
                  (end-of-buffer (throw 'line-fill-paragraph-done nil)))
                (when (> (point) (marker-position end))
                  (throw 'line-fill-paragraph-done nil))
                ;; skip over abbreviations (e.g., i.e.) and punct inside parens (or more!)
                (let ((skipped nil)
                      (s (point))
                      (e nil))
                  (save-excursion
                    (when (re-search-backward " " nil t)
                      (setq e (point))))
                  (when e
                    (let ((last-word (buffer-substring-no-properties s e)))
                      (when (or (string-match abbrev-regexp last-word)
                                (string-match paren-end-regexp last-word))
                        (setq skipped t)
                        (condition-case nil
                            (forward-sentence)
                          (end-of-buffer (throw 'line-fill-paragraph-done nil)))
                        (when (> (point) (marker-position end))
                          (throw 'line-fill-paragraph-done nil)))))
                  (unless skipped
                    (just-one-space) ;; leaves only one space, point is after it
                    (delete-char -1) ;; delete the space
                    (newline)        ;; and insert a newline
                    (indent-region (line-beginning-position) (line-end-position))))))))))))

(provide 'line-fill-paragraph)
;;; line-fill-paragraph.el ends here
