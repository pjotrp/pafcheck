;; To use this file to build a version of pafcheck using git HEAD:
;;
;;   guix build -f guix.scm                  # default build
;;
;; To get a development container using a recent guix (see `guix pull`)
;;
;;   guix shell --share=$HOME/.cargo -L . -C -D -F pafcheck-shell-git # preferred development container
;;
;; and inside the container
;;
;;   rm -rf target/  # may be necessary
;;   CC=gcc cargo build --release
;;
;; list other packages in this guix.scm file
;;
;;   guix package -L . -A pafcheck
;;
;; Installing guix (note that Debian comes with guix). Once installed update as a normal user with:
;;
;;   mkdir ~/opt
;;   guix pull -p ~/opt/guix # update guix takes a while - don't do this often!
;;
;; Use the update guix to build pafcheck:
;;
;;   ~/opt/guix/bin/guix build -f guix.scm
;;
;; Or get a shell
;;
;;   ~/opt/guix/gin/guix build -f guix.scm
;;
;; If things do not work you may also have to update the guix-daemon in systemd. Guix mostly downloads binary
;; substitutes. If it wants to build a lot of software you probably have substitutes misconfigured.

;; by Pjotr Prins (c) 2025

(define-module (guix-pafcheck)
  #:use-module ((guix licenses) #:prefix license:)
  ;; #:use-module (guix build-system cmake)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bioinformatics)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages certs)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages crates-io)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages jemalloc)
  #:use-module (gnu packages linux) ; for util-linux column
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages rust-apps) ; for cargo
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim))

(define %source-dir (dirname (current-filename)))

(define %git-commit
    (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ)))

(define-public pafcheck-base-git
  (package
    (name "pafcheck-base-git")
    (version (git-version "0.1.0" "HEAD" %git-commit))
    (source (local-file %source-dir #:recursive? #t))
    (build-system cargo-build-system)
    (inputs (list curl gnutls lzip openssl pkg-config zlib xz)) ;; mostly for htslib
    (arguments
     `(#:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-clap" ,rust-clap-4)
                       ("rust-rust-htslib" ,rust-rust-htslib-0.38)
                       ("rust-tempfile" ,rust-tempfile-3)
                       ("rust-thiserror" ,rust-thiserror-1))
       ;; #:cargo-development-inputs ()))
       #:cargo-package-flags '("--no-metadata" "--no-verify" "--allow-dirty")
     ))
    (synopsis "pafcheck")
    (description
     "Tool for validating PAF (Pairwise Alignment Format) files against their corresponding FASTA sequences. It ensures that the alignments described in the PAF file match the actual sequences in the FASTA files.")
    (home-page "https://github.com/ekg/pafcheck")
    (license license:expat)))

(define-public pafcheck-shell-git
  "Shell version to use 'cargo build'"
  (package
    (inherit pafcheck-base-git)
    (name "pafcheck-shell-git")
    ;; (version (git-version "0.21" "HEAD" %git-commit))
    (inputs
     (modify-inputs (package-inputs pafcheck-base-git)
         (append binutils coreutils-minimal ;; for the shell
                 )))
    (propagated-inputs (list cmake rust rust-cargo nss-certs openssl perl gnu-make-4.2
                             coreutils-minimal which perl binutils gcc-toolchain pkg-config zlib
                             )) ;; to run cargo build in the shell
    (arguments
     `(
       #:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-clap" ,rust-clap-4)
                       ("rust-rust-htslib" ,rust-rust-htslib-0.38)
                       ("rust-tempfile" ,rust-tempfile-3)
                       ("rust-thiserror" ,rust-thiserror-1)
                       )
       ;; #:cargo-development-inputs ()))
       #:cargo-package-flags '("--no-metadata" "--no-verify" "--allow-dirty")
       #:phases (modify-phases %standard-phases
                               (delete 'configure)
                               (delete 'build)
                               (delete 'package)
                               (delete 'check)
                               (delete 'install)
                               )
     ))
    ))

pafcheck-base-git ;; default deployment build with debug info
