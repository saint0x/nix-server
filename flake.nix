{
  description = "NixOS configuration for a DigitalOcean droplet backend";

  inputs = {
    # Using unstable for potentially newer packages, common in flakes
    # Pin to a specific revision for reproducibility if desired
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 
  };

  outputs = { self, nixpkgs }: 
    let
      # System architecture (adjust if your droplet is ARM, etc.)
      system = "x86_64-linux"; 
      
      # Helper to access packages for the target system
      pkgs = nixpkgs.legacyPackages.${system}; 
    in {
    
    # NixOS configuration entry
    nixosConfigurations.digitalocean-droplet = nixpkgs.lib.nixosSystem {
      inherit system;
      
      modules = [
        # Your main configuration module
        ({ config, pkgs, ... }: {
          imports = [ 
            # <path/to/hardware-configuration.nix> # If you had one
          ];

          # --- Core System Settings ---
          boot.loader.grub.enable = true;
          boot.loader.grub.device = "/dev/vda";
          boot.loader.grub.useOSProber = false;

          networking.useDHCP = true;

          fileSystems."/" = { 
            device = "/dev/vda1"; 
            fsType = "ext4"; 
          };

          time.timeZone = "Etc/UTC";
          i18n.defaultLocale = "en_US.UTF-8";

          # --- Nix Settings ---
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nix.settings.auto-optimise-store = true; # Recommended for servers

          # --- SSH Server ---
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "prohibit-password"; 
          };
          
          # --- User Configuration (Root SSH Key) ---
          users.users.root.openssh.authorizedKeys.keys = [
            # IMPORTANT: Replace with your ACTUAL public SSH key
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyc..." 
          ];

          # --- Required Packages for your Backend ---
          environment.systemPackages = with pkgs; [
            git
            vim
            wget
            
            # Core Nix tooling (nix-shell, nix-build, nix profile etc.)
            nix # Includes the nix command-line tools

            # Utilities for fetching sources (often needed for packaging)
            # Check nixpkgs for the exact names if these don't resolve
            nix-prefetch-scripts # Contains nix-prefetch-url, nix-prefetch-git etc. 
            # Alternatively, fetch individually if preferred:
            # nix-prefetch-git 
            # nix-prefetch-url

            # Add any other tools your backend service might need globally
          ];

          # --- NixOS Version ---
          # Sets the NixOS release for default stateful settings. Match to your install target.
          system.stateVersion = "23.11"; # Adjust if using a different NixOS base version

          # --- Basic Firewall (Recommended) ---
          # Allow SSH connections
          networking.firewall.enable = true;
          networking.firewall.allowedTCPPorts = [ 22 ]; 
          # Add other ports if your backend service listens on them
        })
      ];
    };
  };
}