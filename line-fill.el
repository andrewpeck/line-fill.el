;;; line-fill.el --- Functions for semantic line fill -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023-2026 Andrew Peck

;; Author: Andrew Peck <peckandrew@gmail.com>
;; URL: https://github.com/andrewpeck/line-fill.el
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; Keywords: text writing

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
;; Provides `line-fill' and `line-fill-buffer', which reformat prose so that
;; each sentence occupies its own line. Useful e.g. in LaTeX documents or other
;; version controlled prose, since a change to one sentence produces a minimal
;; diff rather than reflowing an entire paragraph.
;;
;;; Code:

(defvar line-fill-non-separators
  (append
   (list "n.b." "i.e." "e.g." "c.f." "viz." "eg." "ie.")
   ;; single letter initials such as A. B. C.
   (mapcar (lambda (x) (concat (upcase (char-to-string x)) ".")) (number-sequence ?a ?z))))

(defsubst line-fill--abbrev-regexp ()
  "Generate a regular expression for non-separator strings.

Matches one or more spaces followed by any of the specified
non-separator strings.

Returns a concatenated regular expression string for use in line
filling."
  (concat "\\s-+\\("
          (string-join
           (mapcar #'regexp-quote line-fill-non-separators)
           "\\|")
          "\\)"))

;;;###autoload
(defun line-fill-buffer (&optional P)
  "Fill every paragraph in the buffer with one sentence per line.

When called with prefix argument P, call `fill-paragraph' on each paragraph."
  (interactive "P")
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (line-fill-paragraph P)
      (forward-paragraph 1))))

;;;###autoload
(defun line-fill-paragraph (&optional P)
  "Fill paragraph with one sentence per line.

When called with prefix argument P call `fill-paragraph'.
Otherwise split the current paragraph into one sentence per line."
  (interactive "P")
  ;; ordinary fill paragraph when prefix arg is set
  (if P (fill-paragraph P)
    (let ((abbrev-regexp (line-fill--abbrev-regexp))
          (paren-end-regexp "[!?][\"')]+\\'"))
      (save-excursion
        (let* ((fill-column 12345678) ;; relies on dynamic binding
               (para-text (save-excursion
                            (let ((end (progn (forward-paragraph 1) (point))))
                              (backward-paragraph 1)
                              (buffer-substring-no-properties (point) end)))))
          ;; skip paragraphs with no sentence-ending punctuation; fill-paragraph
          ;; would join their lines with no way to re-split them
          (when (let ((case-fold-search nil))
                  (string-match "[a-z0-9)\"'][.!?]\\s-" para-text))
            (fill-paragraph) ;; this will not work correctly if the paragraph is
            ;; longer than 12345678 characters (in which case the
            ;; file must be at least 12MB long. This is unlikely.)
            (let ((end (save-excursion
                         (forward-paragraph 1)
                         (backward-sentence)
                         (point-marker)))) ;; remember where to stop
              (beginning-of-line)
              (catch 'line-fill-done
                (while t
                  ;; advance one sentence; exit cleanly at end of buffer or past end
                  (condition-case nil
                      (forward-sentence)
                    (end-of-buffer (throw 'line-fill-done nil)))
                  (when (> (point) (marker-position end))
                    (throw 'line-fill-done nil))
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
                            (end-of-buffer (throw 'line-fill-done nil)))
                          (when (> (point) (marker-position end))
                            (throw 'line-fill-done nil)))))
                    (unless skipped
                      (just-one-space) ;; leaves only one space, point is after it
                      (delete-char -1) ;; delete the space
                      (newline)        ;; and insert a newline
                      (indent-region (line-beginning-position) (line-end-position)))))))))))))

(provide 'line-fill)
;;; line-fill.el ends here
