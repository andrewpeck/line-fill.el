;;; tests/line-fill-test.el --- ERT tests for line-fill  -*- lexical-binding: t; -*-

;; Copyright (C) 2023-2026 Andrew Peck

;; This file is not part of GNU Emacs.

;;; Commentary:
;; ERT tests for line-fill.el

;;; Code:

(require 'ert)

(setq sentence-end-double-space nil)

(require 'line-fill)

;;; Helpers

(defmacro lfp-with-buffer (content &rest body)
  "Run BODY in a temp buffer pre-filled with CONTENT, point at start."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,content)
     (goto-char (point-min))
     ,@body))

;;; Tests

(ert-deftest lfp-test-two-sentences ()
  "Two sentences in one line become two lines."
  (lfp-with-buffer "Hello world. Goodbye world."
    (line-fill)
    (should (equal (buffer-string) "Hello world.\nGoodbye world."))))

(ert-deftest lfp-test-three-sentences ()
  "Three sentences in one line become three lines."
  (lfp-with-buffer "First sentence here. Second sentence here. Third sentence here."
    (line-fill)
    (should (equal (buffer-string) "First sentence here.\nSecond sentence here.\nThird sentence here."))))

(ert-deftest lfp-test-single-sentence ()
  "A single sentence is left unchanged."
  (lfp-with-buffer "Just one sentence here."
    (line-fill)
    (should (equal (buffer-string) "Just one sentence here."))))

(ert-deftest lfp-test-already-split ()
  "Sentences already on separate lines are left unchanged."
  (lfp-with-buffer "First sentence.\nSecond sentence."
    (line-fill)
    (should (equal (buffer-string) "First sentence.\nSecond sentence."))))

(ert-deftest lfp-test-multiple-spaces-collapsed ()
  "Multiple spaces between sentences are collapsed when splitting."
  (lfp-with-buffer "First sentence.  Second sentence."
    (line-fill)
    (should (equal (buffer-string) "First sentence.\nSecond sentence."))))

(ert-deftest lfp-test-question-mark-sentence ()
  "Sentences ending with question marks are split correctly."
  (lfp-with-buffer "Is this working? Yes it is."
    (line-fill)
    (should (equal (buffer-string) "Is this working?\nYes it is."))))

(ert-deftest lfp-test-exclamation-mark-sentence ()
  "Sentences ending with exclamation marks are split correctly."
  (lfp-with-buffer "Wow it works! Great news."
    (line-fill)
    (should (equal (buffer-string) "Wow it works!\nGreat news."))))

(ert-deftest lfp-test-no-break-after-abbreviation ()
  "Sentences containing e.g. are not split at the abbreviation."
  (lfp-with-buffer "Rodents are mammals. All rodents have continuously growing incisors. Many species are kept as pets, e.g. guinea pigs and hamsters, which are popular due to their docile nature (and we e.g. often see them in schools and homes)."
    (line-fill)
    (should (equal (buffer-string)
                   "Rodents are mammals.\nAll rodents have continuously growing incisors.\nMany species are kept as pets, e.g. guinea pigs and hamsters, which are popular due to their docile nature (and we e.g. often see them in schools and homes)."))))

(ert-deftest lfp-test-no-break-after-paren-exclamation ()
  "Sentences are not split after ! or ? inside parentheses."
  (lfp-with-buffer "Beavers are the largest rodents in North America. Their dams can raise water levels by a surprising amount (or more!) than most people expect."
    (line-fill)
    (should (equal (buffer-string)
                   "Beavers are the largest rodents in North America.\nTheir dams can raise water levels by a surprising amount (or more!) than most people expect."))))

(ert-deftest lfp-test-prefix-arg-calls-fill-paragraph ()
  "When called with a prefix argument, `fill-paragraph' is invoked instead."
  (lfp-with-buffer "First sentence. Second sentence."
    (let ((fill-column 20)
          (fill-paragraph-called nil))
      (cl-letf (((symbol-function 'fill-paragraph)
                 (lambda (&rest _args) (setq fill-paragraph-called t))))
        (line-fill '(4))
        (should fill-paragraph-called)))))

(ert-deftest lfp-test-point-position-preserved ()
  "The function uses `save-excursion', so point is not moved."
  (lfp-with-buffer "First sentence. Second sentence."
    (goto-char (point-min))
    (line-fill)
    (should (= (point) (point-min)))))

(provide 'line-fill-test)
;;; tests/line-fill-test.el ends here
