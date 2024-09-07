{
  lib,
  mkYarnPackage,
  fetchYarnDeps,
  fetchFromGitHub,
}:

mkYarnPackage rec {
  pname = "horizon-card";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "rejuvenate";
    repo = "lovelace-horizon-card";
    rev = "v${version}";
    hash = "sha256-GJzclfyk/HsT5NVRh6T1mUpEAVKWjovH71ZY2JoBUig=";
  };

  offlineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-gx1tDgNa3qRb0IdoLDK7TX0/XhV4bAjEMQSaaS1nQc0=";
  };

  buildPhase = ''
    runHook preBuild

    # The build process expects "rimraf" to be in path, which is installed via yarn
    export PATH=$(pwd)/node_modules/.bin:$PATH
    export HOME=$(mktemp -d)
    yarn run build --offline

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp ./deps/lovelace-horizon-card/dist/lovelace-horizon-card.js $out/

    runHook postInstall
  '';

  doDist = false;

  meta = with lib; {
    description = "Sun Card successor: Visualize the position of the Sun over the horizon";
    homepage = "https://github.com/rejuvenate/lovelace-horizon-card";
    license = licenses.mit;
    maintainers = with maintainers; [ matthiasbeyer ];
    platforms = platforms.all;
  };
}
