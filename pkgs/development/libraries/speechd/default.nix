{ stdenv
, lib
, substituteAll
, pkg-config
, fetchurl
, python3Packages
, gettext
, itstool
, libtool
, texinfo
, util-linux
, autoreconfHook
, glib
, dotconf
, libsndfile
, withLibao ? true, libao
, withPulse ? false, libpulseaudio
, withAlsa ? false, alsa-lib
, withOss ? false
, withFlite ? true, flite
, withEspeak ? true, espeak, sonic, pcaudiolib
, mbrola
, withPico ? stdenv.hostPlatform.isLinux, svox
}:

let
  inherit (python3Packages) python pyxdg wrapPython;
in stdenv.mkDerivation rec {
  pname = "speech-dispatcher";
  version = "0.11.2";

  src = fetchurl {
    url = "https://github.com/brailcom/speechd/releases/download/${version}/${pname}-${version}.tar.gz";
    sha256 = "sha256-i0ZJkl5oy+GntMCge7BBznc4s1yQamAr+CmG2xqg82Q=";
  };

  patches = [
    (substituteAll {
      src = ./fix-paths.patch;
      utillinux = util-linux;
    })
  ] ++ lib.optionals (withEspeak && espeak.mbrolaSupport) [
    # Replace FHS paths.
    (substituteAll {
      src = ./fix-mbrola-paths.patch;
      inherit espeak mbrola;
    })
  ];

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    gettext
    libtool
    itstool
    texinfo
    wrapPython
  ];

  buildInputs = [
    glib
    dotconf
    libsndfile
    libao
    libpulseaudio
    python
  ]  ++ lib.optionals withAlsa [
    alsa-lib
  ] ++ lib.optionals withEspeak [
    espeak
    sonic
    pcaudiolib
  ] ++ lib.optionals withFlite [
    flite
  ] ++ lib.optionals withPico [
    svox
  ];

  pythonPath = [
    pyxdg
  ];

  configureFlags = let 
    backends = 
      lib.optional withLibao "libao" ++
      lib.optional withPulse "pulse" ++
      lib.optional withAlsa "alsa" ++
      lib.optional withOss "oss";
  in
  [
    # Audio method falls back from left to right.
    "--with-default-audio-method=\"${builtins.concatStringsSep "," backends}\""
    "--with-systemdsystemunitdir=${placeholder "out"}/lib/systemd/system"
  ] ++ lib.optionals withPulse [
  "--with-pulse"
  ] ++ lib.optionals withAlsa [
    "--with-alsa"
  ] ++ lib.optionals withLibao [
    "--with-libao"
  ] ++ lib.optionals withOss [
    "--with-oss"
  ] ++ lib.optionals withEspeak [
    "--with-espeak-ng"
  ] ++ lib.optionals withPico [
    "--with-pico"
  ];

  postPatch = lib.optionalString withPico ''
    substituteInPlace src/modules/pico.c --replace "/usr/share/pico/lang" "${svox}/share/pico/lang"
  '';

  postInstall = ''
    wrapPythonPrograms
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Common interface to speech synthesis";
    homepage = "https://devel.freebsoft.org/speechd";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      berce
      jtojnar
    ];
    platforms = platforms.linux ++ platforms.darwin;
    # Does not build on darwin because of the use of __attribute__ ((weak, "symbol")) which isn't supported
  };
}
