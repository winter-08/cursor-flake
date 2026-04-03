# cursor-flake

Cursor `3.0.9`, packaged as a flake for:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Usage

Run it directly:

```bash
nix run .#cursor
```

Install it to your profile:

```bash
nix profile install .#cursor
```

## NixOS

```nix
{
  inputs.cursor.url = "path:/path/to/cursor-flake";

  outputs = { self, nixpkgs, cursor, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        cursor.nixosModules.default
        {
          programs.cursor.enable = true;
        }
      ];
    };
  };
}
```

## nix-darwin

```nix
{
  inputs.cursor.url = "path:/path/to/cursor-flake";

  outputs = { self, nixpkgs, darwin, cursor, ... }: {
    darwinConfigurations.my-mac = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        cursor.darwinModules.default
        {
          programs.cursor.enable = true;
        }
      ];
    };
  };
}
```

## Updating

```bash
bash ./update.sh
```

The updater queries Cursor's official stable download API and rewrites [`sources.json`](./sources.json).

## Automation

A daily GitHub Actions workflow lives at [`.github/workflows/cursor-version-bump.yml`](./.github/workflows/cursor-version-bump.yml). It:

- checks Cursor's stable release once per day
- runs `update.sh`
- opens or updates a PR when `sources.json` changes
