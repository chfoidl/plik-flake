{ lib, fetchurl, stdenv, pkgs, ... }: let
  pname = "plik";
  version = "1.3.8";

  inherit (stdenv.hostPlatform) system;
  sources = import ./sources.nix {
    inherit version fetchurl;
  };
in stdenv.mkDerivation {
  inherit pname version;

  src = sources.${system} or (throw "Source for ${pname} is not available for ${system}");

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/server
    mkdir -p $out/webapp
    mkdir -p $out/clients
    mkdir -p $out/changelog

    cp -R server $out
    cp -R webapp $out
    cp -R clients $out
    cp -R changelog $out

    ln -s $out/server/plikd $out/bin/plikd
  '';
}
