#!/bin/sh

if test -e "`ocamlopt -where 2>/dev/null || ocamlc -where`/graphics.cmi" ; then
  # Graphics library already installed
  exit 0
fi

VERSION=`ocamlopt -version 2>/dev/null || ocamlc -version`
VERSION=`echo $VERSION | sed -e 's/[+.]//g'`

# Installation variables in the Makefile altered with 4.02.0
if test $VERSION -ge 4020 ; then
  K_LIBDIR=INSTALL_LIBDIR
  K_STUBLIBDIR=INSTALL_STUBLIBDIR
else
  K_LIBDIR=LIBDIR
  K_STUBLIBDIR=STUBLIBDIR
fi

if test "$1" = "build" ; then
  # For system compilers, use the real OCaml LIBDIR, otherwise use the opam one
  if $2 ; then
    OCAML_LIBDIR="`ocamlopt -where 2>/dev/null || ocamlc -where`"
  else
    OCAML_LIBDIR="$3"
  fi

  # Configure the source tree
  if test $VERSION -ge 3090 ; then
    if test $VERSION -ge 4040 ; then
      # reconfigure target introduced in 4.04.0
      cp "$OCAML_LIBDIR/Makefile.config" config/Makefile
      $4 reconfigure
    else
      # Otherwise, execute the first line from Makefile.config (which includes
      # the arguments used)
      `sed -ne '1s/# generated by //p' "$OCAML_LIBDIR/Makefile.config"`
    fi
  else
    # Prior to OCaml 3.09.0, config/Makefile wasn't installed, so we just have
    # to make a buest guess
    ./configure -libdir "$OCAML_LIBDIR"
  fi

  # Build the library
  $4 -C otherlibs/graph CAMLC=ocamlc CAMLOPT=ocamlopt MKLIB=ocamlmklib all $5

  if ! $2 ; then
    # System compilers must always have META installed (since ocamlfind either
    # won't have installed it, or won't create it when installed), but otherwise
    # it should only be installed if ocamlfind is already installed (since a
    # subsequent installation will detect the graphics library and install META)
    if ! test -e "$3/topfind" ; then
      rm META
    fi
  fi
else
  if test -e META ; then
    mkdir -p "$3"
    cp -f META "$3/META"
  fi

  if $2 ; then
    $4 "$K_LIBDIR=$3" "$K_STUBLIBDIR=$5" -C otherlibs/graph install $6
  else
    $4 -C otherlibs/graph install $6
  fi
fi
