{
  inputs,
  den,
  lib,
  ...
}:
{
  den.default.includes = [ den.aspects.routes den._.home-manager ];

  den.hosts.x86_64-linux.igloo.users.tux = { };

  den.aspects.igloo = {
    provides.tux = den.lib.parametric {
      includes = [
        den.aspects.testing
      ];
    };
  };
  # Use aspects to create a **minimal** bug reproduction
  den.aspects.testing =
    { user, ... }@ctx:
    {
      homeManager = { pkgs, ... }: { home.packages = [ pkgs.vim ]; };
    };

  # `nix-unit --flake .#.tests.systems`
  # `nix eval .#.tests.testItWorks`
  flake.tests.testItWorks =
    let
      igloo = inputs.self.nixosConfigurations.igloo.config;
      tux = igloo.home-manager.users.tux;

      expr = lib.lists.count (p: builtins.match "vim-.*" p.name != null) tux.home.packages;
      expected = 1;
    in
    {
      inherit expr expected;
    };

  # See [Debugging Tips](https://den.oeiuwq.com/debugging.html)
  flake.den = den;
  # `nix eval .#.value`
  # This doesn't show the bug
  flake.value =
    let
      aspect = den.aspects.testing {
        user.userName = "tux";
        host.hostName = "fake";
      };
      modules = [
        { _module.args = { pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; }; }
        (aspect.resolve { class = "homeManager"; })
        { options.home.packages = lib.mkOption { type = lib.types.listOf lib.types.package; default = []; }; }
      ];
      evaled = lib.evalModules { inherit modules; };
    in
    evaled.config;

}
