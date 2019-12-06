{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "drihybrisproto";
  version = "unstable-2018-12-16";

  src = fetchFromGitHub {
    owner = "NotKit";
    repo = "drihybris";
    rev = "3291c0ff9af4a2568474aa7b1b0a3786818705dc";
    sha256 = "0300q2yhi4g5rx2pd6scc92j6kypsa2hl6v04sk0mvf88vcrzh7k";
  };

  dotConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -Dm644 src/drihybrisproto.h $out/include/X11/extensions/drihybrisproto.h
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/NotKit/drihybris;
    description = "X11 DRIHYBRIS protocol";
    maintainers = with maintainers; [ adisbladis ];
    platforms = stdenv.lib.platforms.linux;
    license = licenses.mit;  #x11
  };

}
