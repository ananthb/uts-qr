{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "uts-qr";

  buildInputs = with pkgs; [
    hugo
    nodejs
    wrangler
    elmPackages.elm
  ];
}
