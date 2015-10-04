(in-package :cl-user)

(require :asdf)

(defvar *build-dir* (pathname (concatenate 'string (uiop:getenv "BUILD_DIR") "/")))
(defvar *cache-dir* (pathname (concatenate 'string (uiop:getenv "CACHE_DIR") "/")))
(defvar *buildpack-dir* (pathname (concatenate 'string (uiop:getenv "BUILDPACK_DIR") "/")))

(defmacro fncall (funname &rest args)
  `(funcall (read-from-string ,funname) ,@args))

(defun require-quicklisp (&key version)
  "VERSION if specified must be in format YYYY-MM-DD"
  (let ((ql-setup (merge-pathnames "quicklisp/setup.lisp" *cache-dir*)))
    (if (probe-file ql-setup)
        (progn (format t "Quicklisp already installed...~%Loading.....~%") 
               (load ql-setup))
        (progn
          (format t "Quicklisp not detected...~%Installing Quicklisp....~%")
          (load (merge-pathnames "bin/quicklisp.lisp" *buildpack-dir*))
          (fncall "quicklisp-quickstart:install"
                   :path (make-pathname :directory (pathname-directory ql-setup)))))
    (when version
      (fncall "ql-dist:install-dist"
              (format nil "http://beta.quicklisp.org/dist/quicklisp/~A/distinfo.txt"
                      version)
              :replace t :prompt nil))))

(defun call-with-ql-test-context (thunk)
  (block nil
    (handler-bind (((or error serious-condition)
                     (lambda (c)
                       (format *error-output* "~%~A~%" c)
                       (print-backtrace)
                       (format *error-output* "~%~A~%" c)
                       (return nil))))
      (funcall thunk))))

(defmacro with-ql-test-context (() &body body)
  `(call-with-ql-test-context #'(lambda () ,@body)))

;;; Load the application compile script
(with-ql-test-context ()
  (load (merge-pathnames "heroku-compile.lisp" *build-dir*)))
