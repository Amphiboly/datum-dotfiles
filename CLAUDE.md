# Refactoring Goals
- Target Architecture: Modular dendritic structure (one app/tool per file).
- Multi-user Support: Separate system-level privileges from user-level Home Manager privileges. Users must be able to change configurations within their privilege scope without needing full system rebuild access.
- Decoupling: Home Manager modules should be extractable and usable independently from the core monolithic `nixosConfigurations`.

# Architectural Rules
- Avoid multi-file global rewrites in a single command.
- Validate changes incrementally using `nix flake check` or `nix eval`.
- Follow idiomatic module structures using `options`, `config`, and `imports`.

