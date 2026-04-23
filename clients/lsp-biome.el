;;; lsp-biome.el --- lsp-mode biome integration -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Justin Barclay

;; Author: Justin Barclay <github@justinbarclay.ca>
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'lsp-mode)

(defgroup lsp-biome nil
  "Biome language server group."
  :group 'lsp-mode
  :link '(url-link "https://github.com/biomejs/biome"))

(lsp-defcustom lsp-biome-enabled t
  "Controls whether the Biome extension is active and provides its features
in the context to which this setting applies."
  :type 'boolean
  :group 'lsp-biome
  :package-version '(lsp-mode . "9.0.0")
  :lsp-path "biome.enabled")

(lsp-defcustom lsp-biome-lsp-bin nil
  "Path to a custom Biome binary.

When set, the extension will use this path and will not attempt to
locate Biome automatically."
  :type '(choice (const :tag "Default" nil) string (alist :key-type string :value-type string))
  :group 'lsp-biome
  :package-version '(lsp-mode . "9.0.0")
  :lsp-path "biome.lsp.bin")

(defun lsp-biome--server-command ()
  "Find the biome server command.
Tries to find the command in the PATH or looks in node_modules."
  (let ((cmd (or lsp-biome-lsp-bin
                 (executable-find "biome")
                 (let ((root (lsp-workspace-root)))
                   (when root
                     (let ((cmd (expand-file-name "node_modules/.bin/biome" root)))
                       (when (file-executable-p cmd) cmd)))))))
    (list cmd "lsp-proxy")))

;;;###autoload
(defun lsp-biome-fix-all ()
  "Perform the source.fixAll.eslint code action, if available."
  (interactive)
  (condition-case nil
      (lsp-execute-code-action-by-kind "source.fixAll.biome")
    (lsp-no-code-actions
     (when (called-interactively-p 'any)
       (lsp--info "source.fixAll.biome action not available")))))

;;;###autoload
(defun lsp-biome-organize-imports ()
  "Perform the source.fixAll.eslint code action, if available."
  (interactive)
  (condition-case nil
      (lsp-execute-code-action-by-kind "source.organizeImports.biome")
    (lsp-no-code-actions
     (when (called-interactively-p 'any)
       (lsp--info "source.organizeImports.biome action not available")))))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection #'lsp-biome--server-command)
  :initialization-options (lambda () (lsp-configuration-section "biome"))
  :activation-fn (lambda (filename _mode)
                   (and lsp-biome-enabled
                        (member (lsp-buffer-language)
                                '("astro"
                                  "css"
                                  "graphql"
                                  "javascript"
                                  "javascriptreact"
                                  "json"
                                  "jsonc"
                                  "svelte"
                                  "typescript"
                                  "typescriptreact"
                                  "html"
                                  "vue"))))
  :add-on? t
  :multi-root t
  :priority -1
  :server-id 'biome))

(lsp-consistency-check lsp-biome)

(provide 'lsp-biome)
;;; lsp-biome.el ends here
