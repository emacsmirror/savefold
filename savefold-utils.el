;;; savefold-utils.el --- shared utilities for savefold -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Jacob Fong
;; Author: Jacob Fong <jacobcfong@gmail.com>
;; Version: 0.1
;; Homepage:

;; Package-Requires: ((emacs "28.2"))

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the “Software”), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; Shared utilities for savefold

;;; Code:

(defvar savefold-utils--fpath-to-attr-table (make-hash-table :test 'equal)
  "Hash table mapping file paths to file attribute hash tables.")

(defun savefold-utils--get-attr-table-fpath (fpath)
  "Return the fpath of the attribute table file for FPATH.

This naively replaces path slashes with ! (/a/b/c -> !a!b!c) leading to a chance
of collision."
  (expand-file-name
   (string-replace "/" "!" (expand-file-name fpath))
   savefold-directory))

(defun savefold-utils--get-file-attr-table (fpath)
  "Get the attribute hash table for file FPATH.

If no attr table file exists, return a new hash table."
  (let ((attr-table (gethash fpath savefold-utils--fpath-to-attr-table)))
    (when (not attr-table)
      (let ((attr-table-fpath (savefold-utils--get-attr-table-fpath fpath)))
        (if (file-exists-p attr-table-fpath)
            (setq attr-table
                  (with-temp-buffer
                    (insert-file-contents attr-table-fpath)
                    (goto-char (point-min))
                    (read (current-buffer))))
          (setq attr-table (make-hash-table))))
      (puthash fpath attr-table savefold-utils--fpath-to-attr-table))
    attr-table))

(defun savefold-utils-get-file-attr (attr &optional fpath)
  "Return attribute ATTR for the current file.

Use FPATH instead if non-nil."
  (when-let ((fpath (or fpath
                        (and (buffer-file-name) (expand-file-name (buffer-file-name))))))
    (gethash attr (savefold-utils--get-file-attr-table fpath))))

(defun savefold-utils-set-file-attr (attr value &optional fpath)
  "Set attribute ATTR for VALUE in the current file's hash table.

Make sure to `savefold-utils-write-out-file-attrs' after each batch of changes
to save them to the disk.

Use FPATH instead of the current buffer file if non-nil."
  (when-let ((fpath (or fpath
                        (and (buffer-file-name) (expand-file-name (buffer-file-name))))))
    (if (readablep value)
        (puthash attr value (savefold-utils--get-file-attr-table fpath))
      (error "file attr value must be readable"))))

(defun savefold-utils-write-out-file-attrs (&optional fpath)
  "Write attr hash table for the current file to the disk.

Use FPATH instead if non-nil."
  (when-let ((fpath (or fpath
                        (and (buffer-file-name) (expand-file-name (buffer-file-name))))))
    (when (not (file-exists-p savefold-directory))
      (make-directory savefold-directory))
    (with-temp-file (savefold-utils--get-attr-table-fpath fpath)
      (prin1
       (gethash fpath savefold-utils--fpath-to-attr-table)
       (current-buffer)))))

(provide 'savefold-utils)

;;; savefold-utils.el ends here
