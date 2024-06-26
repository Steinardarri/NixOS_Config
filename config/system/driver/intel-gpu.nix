{
  pkgs,
  lib,
  hostname,
  ...
}: let
  inherit (import ../../../hosts/${hostname}/options.nix) gpuType;
in
  lib.mkIf ("${gpuType}" == "intel") {
    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override {
        enableHybridCodec = true;
      };
    };

    # OpenGL
    hardware.opengl = {
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  }
