{
  description = "NixOS configuration for a DigitalOcean droplet backend";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux"; 
      pkgs = nixpkgs.legacyPackages.${system}; 
      
      # Define the NixOS configuration module list in one place
      nixosModule = { config, pkgs, lib, nixpkgs, ... }: { # Changed to a single module, not a list of functions
          imports = [ 
            # <path/to/hardware-configuration.nix> 
            # Use the passed nixpkgs argument
            (nixpkgs + "/nixos/modules/virtualisation/digital-ocean-image.nix")
          ];

          # --- Core System Settings ---
          boot.loader.grub.enable = true;
          boot.loader.grub.device = "/dev/vda"; # Specify device for DigitalOcean
          boot.loader.grub.useOSProber = false; 
          # Needed for DO image generation
          boot.loader.grub.default = lib.mkForce 0; 

          networking.useDHCP = true;

          fileSystems."/" = { 
            device = "/dev/vda1"; # Image builder will create this partition
            fsType = "ext4"; 
          };

          # --- Image Build Settings ---
          # Enable building the DigitalOcean image format (compressed qcow2)
          # This option implicitly sets up necessary partitioning etc.
          virtualisation.digitaloceanImage.enable = true;
          # Optionally set the compressed image size if needed (default might be fine)
          # virtualisation.digitaloceanImage.compressedSize = "5G"; 

          time.timeZone = "Etc/UTC";
          i18n.defaultLocale = "en_US.UTF-8";

          # --- Nix Settings ---
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nix.settings.auto-optimise-store = true;

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

          # --- Required Packages ---
          environment.systemPackages = with pkgs; [
            git
            vim
            wget
            nix 
            nix-prefetch-scripts
          ];

          # --- NixOS Version ---
          system.stateVersion = "23.11"; # Adjust if needed

          # --- Basic Firewall ---
          networking.firewall.enable = true;
          networking.firewall.allowedTCPPorts = [ 22 ]; 
        };
      
      # Build the NixOS system using the defined modules
      nixosSystem = nixpkgs.lib.nixosSystem {
        inherit system;
        # Pass the single module directly
        modules = [ nixosModule ];
        # Pass nixpkgs input as a special argument
        specialArgs = { inherit nixpkgs; }; 
      };

    in {
    
    # Expose the NixOS configuration itself
    nixosConfigurations.digitalocean-droplet = nixosSystem;

    # --- ADD THIS ---
    # Expose the DigitalOcean image derivation directly
    # This allows 'nix build .#digitalOceanImage'
    digitalOceanImage = nixosSystem.config.system.build.digitalOceanImage;

    # --- Optional: Expose a default package (e.g., for 'nix build') ---
    # defaultPackage.${system} = self.digitalOceanImage; 
    # Or expose something else if more appropriate
  };
}