{ stdenvNoCC, lib, writeText }:

/*  */ let scope = { "fileSystem.makeFilesystem" =

let
  inherit (lib) optionals optionalString assertMsg;
in

{
  name
  # Size (in bytes) the filesystem image will be given.
  # When size is not given, it is assumed that `populateCommands` will populate
  # the filesystem, and the size will be derived (see computeMinimalSize).
  , size ? null

  # The populate commands are executed in a subshell. The CWD at the star is the
  # public API to know where to add files that will be added to the image.
  , populateCommands ? null

  # Used with the assumption that files are rounded up to blockSize increments.
  , blockSize

  # Additional commands to compute a required increase in size to fit files.
  , computeMinimalSize ? null

  # When automatic sizing is used, additional amount of bytes to pad the image by.
  , extraPadding ? 0
  , ...
} @ args:

assert lib.asserts.assertMsg
  (size !=null || populateCommands != null)
  "Either a size or populateCommands needs to be given to build a filesystem.";

let
  partName = name;
in
stdenvNoCC.mkDerivation (args // rec {
  # Do not inherit `size`; we don't want to accidentally use it. The `size` can
  # be dynamic depending on the contents.
  inherit partName blockSize;

  name = "partition-${partName}";
  filename = "${partName}.img";
  img = "${placeholder "out"}/${filename}";

  nativeBuildInputs = [
  ] ++ optionals (args ? nativeBuildInputs) args.nativeBuildInputs;

  buildCommand = ''
    adjust-minimal-size() {
      size="$1"

      echo "$size"
    }

    compute-minimal-size() {
      local size=0
      (
      cd files
      # Size rounded in blocks. This assumes all files are to be rounded to a
      # multiple of blockSize.
      # Use of `--apparent-size` is to ensure we don't get the block size of the underlying FS.
      # Use of `--block-size` is to get *our* block size.
      size=$(find . ! -type d -print0 | du --files0-from=- --apparent-size --block-size "$blockSize" | cut -f1 | sum-lines)
      echo "Reserving $size sectors for files..." 1>&2

      # Adds one blockSize per directory, they do take some place, in the end.
      # FIXME: write test to confirm this assumption
      local directories=$(find . -type d | wc -l)
      echo "Reserving $directories sectors for directories..." 1>&2

      size=$(( directories + size ))

      size=$((size * blockSize))

      ${if computeMinimalSize == null then "" else computeMinimalSize}

      size=$(( size + ${toString extraPadding} ))

      echo "$size"
      )
    }

    sum-lines() {
      local acc=0
      while read -r number; do
          acc=$((acc+number))
      done

      echo "$acc"
    }


    # The default stdenv/generic clashes with `runHook`.
    # It doesn't override as expected.
    unset -f checkPhase

    mkdir -p $out
    mkdir -p files

    ${optionalString (populateCommands != null) ''
    echo
    echo "Populating disk image"
    echo
    (
      cd files
      ${populateCommands}
    )
    ''}
    ${optionalString (size == null) ''
      size=$(compute-minimal-size)
    ''}

    if (( size < minimumSize )); then
      size=$minimumSize
      echo "WARNING: the '$partName' partition was too small, size increased to $minimumSize bytes."
    fi

    echo
    echo "Building partition ${partName}"
    echo "With ${if size == null
      then "automatic size ($size bytes)"
      else "$size bytes"
    }"
    echo

    echo " -> Allocating space"
    truncate -s $size "$img"

    echo " -> Making filesystem"
    runHook filesystemPhase

    echo " -> Copying files"
    (
      cd files
      runHook copyPhase
    )

    echo " -> Checking filesystem"
    echo "$checkPhase"
    runHook checkPhase

    if [ -n "$postProcess" ]; then
      echo "-> Running post-processing"
      runHook postProcess
    fi
  '';

})
    # mkdir -p $out/nix-support
    # cat ${writeText "${name}-metadata" (builtins.toJSON {
    #   inherit size;
    # })} > $out/nix-support/partition-metadata.json

/*  */ ;}; in scope."fileSystem.makeFilesystem"
