{ config
, lib
, stdenv
, fetchFromGitHub
, alsa-lib
, autoconf
, automake
, libpulseaudio
, libtool
, pkg-config
, portaudio
, which
, pulseaudioSupport ? config.pulseaudio or stdenv.isLinux
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pcaudiolib";
  version = "unstable-2023-03-12";

  src = fetchFromGitHub {
    owner = "espeak-ng";
    repo = "pcaudiolib";
    rev = "494e7cda93b03539288999094001f49c5c4e9bdf";
    hash = "sha256-QS2JSMY5hhSmkBup7bDZdzHMNYSdnkeDubxQUQssyLg=";
  };

  nativeBuildInputs = [
    autoconf
    automake
    libtool
    pkg-config
    which
  ];

  buildInputs = [
    portaudio
  ]
  ++ lib.optional stdenv.isLinux alsa-lib
  ++ lib.optional pulseaudioSupport libpulseaudio;

  preConfigure = ''
    ./autogen.sh
  '';

  meta = with lib; {
    homepage = "https://github.com/espeak-ng/pcaudiolib";
    description = "Provides a C API to different audio devices";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ aske ];
    platforms = platforms.unix;
  };
})
