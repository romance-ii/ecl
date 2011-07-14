;;;;  -*- Mode: Lisp; Syntax: Common-Lisp; Package: C -*-
;;;;
;;;;  Copyright (c) 1984, Taiichi Yuasa and Masami Hagiya.
;;;;  Copyright (c) 1990, Giuseppe Attardi.
;;;;  Copyright (c) 2001, Juan Jose Garcia Ripoll
;;;;
;;;;    This program is free software; you can redistribute it and/or
;;;;    modify it under the terms of the GNU Library General Public
;;;;    License as published by the Free Software Foundation; either
;;;;    version 2 of the License, or (at your option) any later version.
;;;;
;;;;    See file '../Copyright' for full details.

;;;; BYTECMP Fake compiler which is used as a replacement when we do not
;;;;         want or can have the real native compiler.

(in-package "EXT")

(defun bc-compile (name &optional (def nil supplied-p))
 (cond ((and supplied-p def)
        (when (functionp def)
	  (unless (function-lambda-expression def)
          (return-from bc-compile def))
	  (setf def (function-lambda-expression def)))
        (setq form (if name
		     `(setf (symbol-function ',name) #',def)
		     `(set 'GAZONK #',def))))
       ((not (fboundp name))
	(error "Symbol ~s is unbound." name))
       ((typep (setf def (symbol-function name)) 'standard-generic-function)
	(warn "COMPILE can not compile generic functions yet")
	(return-from bc-compile (values def t nil)))
       ((null (setq form (function-lambda-expression def)))
	(warn "We have lost the original function definition for ~s. Compilation failed"
              name)
	(return-from bc-compile (values def t nil)))
       (t
	(setq form `(setf (symbol-function ',name) #',form))))
 (eval form)
 (values name nil nil))

(defun bc-compile-file-pathname (name &key (output-file name) (type :fasl type-supplied-p)
				 verbose print c-file h-file data-file shared-data-file
				 system-p load)
  (let ((extension "fasc"))
    (case type
      ((:fasl :fas) (setf extension "fasc"))
      (t (error "In COMPILE-FILE-PATHNAME, the type ~A is unsupported." type)))
    (make-pathname :type extension :defaults output-file)))

(defun bc-compile-file (input
			&key
			((:verbose *compile-verbose*) *compile-verbose*)
			((:print *compile-print*) *compile-print*)
			(load nil)
			(output-file nil output-file-p)
			&allow-other-keys)
  (setf output-file (if output-file-p
                        (pathname output-file)
                        (bc-compile-file-pathname input)))
  (when *compile-verbose*
    (format t "~&;;; Compiling ~A" input))
  (cond ((not (streamp input))
         (let ((ext:*source-location* (cons (truename input) 0)))
           (with-open-file (sin input :direction :input)
             (bc-compile-file sin :output-file output-file))))
        ((not output-file-p)
         (error "COMPILE-FILE invoked with a stream input and no :OUTPUT-FILE"))
        (t
         (with-open-file (sout output-file :direction :output :if-exists :supersede
                               :if-does-not-exist :create)
           (handler-case
               (sys:with-ecl-io-syntax
                   (write (loop with *package* = *package*
                             with x = (intern "+C1-FORM-HASH+" (find-package "C"))
                             with ext:*bytecodes-compiler* = t
                             for y = (and (boundp x) (symbol-value x))
                             for position = (file-position input)
                             for form = (read input nil :EOF)
                             until (eq form :EOF)
                             do (when ext::*source-location*
                                  (rplacd ext:*source-location* position))
                             do (unless (or (null x) (hash-table-p y))
                                  (print y)
                                  (print form)
                                  (setf x nil))
                             collect (si:eval-with-env form nil nil nil nil))
                          :stream sout :circle t
                          :escape t :readably t :pretty nil)
                 (terpri sout))
             (error (c) (let ((*print-readably* nil)
                              (*print-pretty* nil)
                              (*print-circle* t))
                          (break)))))))
  (when load
    (load output-file :verbose *compile-verbose*))
  (values output-file nil nil))

(defun install-bytecodes-compiler ()
  (ext::package-lock (find-package :cl) nil)
  (pushnew :ecl-bytecmp *features*)
  (setf (fdefinition compile) #'bc-compile
        (fdefinition compile-file) #'bc-compile-file
        (fdefinition compile-file-pathname) #'bc-compile-file-pathname)
  (ext::package-lock (find-package :cl) t))

#-ecl-min
(progn
#-windows
(sys::autoload "SYS:cmp" 'compile-file 'compile 'compile-file-pathname 'disassemble)
#+windows
(ext:install-bytecodes-compiler)
)

(provide 'BYTECMP)

#-ecl-min
(package-lock "COMMON-LISP" t)
