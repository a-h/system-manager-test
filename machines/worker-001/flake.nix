{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";

    system-manager = {
      url = "github:numtide/system-manager/e8957ab8b4cf02574adb5f09ef4a2ef9ee48ef01";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, nixpkgs, system-manager }: {
    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        ./modules
      ];
    };
  };
}
