{
  alsa-lib,
  clangStdenv,
  cmake,
  curl,
  expat,
  fetchFromGitHub,
  fontconfig,
  freetype,
  lib,
  libGL,
  libXcursor,
  libXext,
  libXinerama,
  libXrandr,
  libepoxy,
  libjack2,
  libxkbcommon,
  lv2,
  ninja,
  pkg-config,
  writableTmpDirAsHomeHook,
}:

clangStdenv.mkDerivation (finalAttrs: {
  pname = "zlequalizer";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "ZL-Audio";
    repo = "ZLEqualizer";
    tag = "${finalAttrs.version}";
    hash = "sha256-9TmvjBXTrvR0+qnGDFhCczanxiry3d43QVn/pJLUREY=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    writableTmpDirAsHomeHook
  ];

  buildInputs = [
    alsa-lib
    curl
    expat
    fontconfig
    freetype
    libGL
    libXcursor
    libXext
    libXinerama
    libXrandr
    libepoxy
    libjack2
    libxkbcommon
    lv2
  ];

  # JUCE dlopen's these at runtime, crashes without them
  NIX_LDFLAGS = (
    toString [
      "-lX11"
      "-lXext"
      "-lXcursor"
      "-lXinerama"
      "-lXrandr"
    ]
  );

  # LTO needs special setup on Linux
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'juce::juce_recommended_lto_flags' '# Not forcing LTO'
  '';

  cmakeFlags = [
    (lib.cmakeFeature "KFR_ARCHS" (if clangStdenv.isAarch64 then "neon64" else "sse2;avx;avx2"))
    (lib.cmakeFeature "ZL_JUCE_COPY_PLUGIN" "FALSE")
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/{lv2,vst3}
    mkdir -p $out/bin/

    cp -r "ZLEqualizer_artefacts/Release/LV2/ZL Equalizer 2.lv2" $out/lib/lv2/
    cp -r "ZLEqualizer_artefacts/Release/VST3/ZL Equalizer 2.vst3" $out/lib/vst3/
    install -Dm755 "ZLEqualizer_artefacts/Release/Standalone/ZL Equalizer 2" $out/bin/

    runHook postInstall
  '';

  meta = {
    homepage = "https://zl-audio.github.io/plugins/zlequalizer2/";
    description = "Versatile equalizer plugin for VST3, LV2 and standalone";
    license = [ lib.licenses.agpl3Plus ];
    maintainers = [ lib.maintainers.magnetophon ];
    platforms = lib.platforms.linux;
  };
})
