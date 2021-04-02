{ lib, imageBuilder, libfaketime, e2fsprogs, make_ext4fs }:

/*  */ let scope = { "fileSystem.makeExt4" =

let
  inherit (lib.strings) splitString;
  inherit (imageBuilder) makeFilesystem;

  # Bash doesn't do floating point representations. Multiplications and divisions
  # are handled with enough precision that we can multiply and divide to get a precision.
  precision = 1000;

  first = list: lib.lists.last (lib.lists.reverseList list);
  chopDecimal = f: first (splitString "." (toString f));
  makeFudge = f: toString (chopDecimal (f * precision));

  # This applies only to 256MiB and greater.
  # For smaller than 256MiB images the overhead from the FS is much greater.
  # This will also let *some* slack space at the end at greater sizes.
  # This is the value at 512MiB where it goes slightly down compared to 256MiB.
  fudgeFactor = makeFudge 0.05208587646484375;

  # This table was built using a script that built an image with `make_ext4fs`
  # for the given size in MiB, and recorded the available size according to `df`.
  smallFudgeLookup = lib.strings.concatStringsSep "\n" (lib.lists.reverseList(
    lib.attrsets.mapAttrsToList (size: factor: ''
      elif (( size > ${toString size} )); then
        fudgeFactor=${toString factor}
    '') {
    "${toString (imageBuilder.size.MiB   5)}" = makeFudge 0.84609375;
    "${toString (imageBuilder.size.MiB   8)}" = makeFudge 0.5419921875;
    "${toString (imageBuilder.size.MiB  16)}" = makeFudge 0.288818359375;
    "${toString (imageBuilder.size.MiB  32)}" = makeFudge 0.1622314453125;
    "${toString (imageBuilder.size.MiB  64)}" = makeFudge 0.09893798828125;
    "${toString (imageBuilder.size.MiB 128)}" = makeFudge 0.067291259765625;
    "${toString (imageBuilder.size.MiB 256)}" = makeFudge 0.0518646240234375;
  }
  ));

  minimumSize = imageBuilder.size.MiB 5;
in
{ partitionID
, blockSize ? imageBuilder.size.KiB 4
, ... } @ args:
makeFilesystem (args // {
  filesystemType = "ext4";

  inherit blockSize minimumSize;

  nativeBuildInputs = [
    e2fsprogs
    make_ext4fs
    libfaketime
  ];

  filesystemPhase = ''
    :
  '';

  computeMinimalSize = ''
    # `local size` is in bytes.

    # We don't have a static reserved factor figured out. It is rather hard with
    # ext4fs as there are multiple factors increasing the overhead.
    local reservedSize=0
    local fudgeFactor=${toString fudgeFactor}
    
    # Instead we rely on a lookup table. See how it is built in the derivation file.
    if (( size < ${toString (imageBuilder.size.MiB 256)} )); then
      echo "$size is smaller than 256MiB; using the lookup table." 1>&2
      
      # A bit of a hack, though allows us to build the lookup table using only
      # elifs.
      if false; then
        :
      ${smallFudgeLookup}
      else
        # The data is smaller than 5MiB... The filesystem image size will likely
        # not be able to accomodate... here we handle it in another way.
        fudgeFactor=0
        echo "Fudge factor skipped for extra small partition. Instead increasing by a fixed amount." 1>&2
        size=$(( size + ${toString minimumSize}))
      fi
    fi

    local reservedSize=$(( size * $fudgeFactor / ${toString precision} ))

    echo "Fudge factor: $fudgeFactor / ${toString precision}" 1>&2
    echo -n "Adding reservedSize: $size + $reservedSize = " 1>&2
    size=$((size + reservedSize))
    echo "$size" 1>&2
  '';

  copyPhase = ''
    faketime -f "1970-01-01 00:00:01" \
      make_ext4fs \
      -b $blockSize \
      -L $partName \
      -l $size \
      -U $partitionID \
      "$img" \
      .
  '';

  checkPhase = ''
  '';
    # FIXME:
    # Padding at end of inode bitmap is not set. Fix? no
    # exit code
    #EXT2FS_NO_MTAB_OK=yes fsck.ext4 -n -f $img
})

/*  */ ;}; in scope."fileSystem.makeExt4"
