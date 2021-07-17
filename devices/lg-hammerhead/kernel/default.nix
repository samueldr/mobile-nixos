{ stdenv, fetchFromGitLab, buildPackages, fetchurl, perl, buildLinux, ... } @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "5.6.0-rc6";
  modDirVersion = version;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitLab {
    owner = "postmarketOS";
    repo = "linux-postmarketos";
    rev = "b9f39bdf61e5c8f5db63afe7ab1c9ff77aa6b4bc";
    sha256 = "105v5gzqc4avdwzm6y2mz52c08dnv8m4fj7n4l0vdqrz7y1rdabs";
  };
} // (args.argsOverride or {}))
