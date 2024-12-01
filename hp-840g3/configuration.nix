# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:

let
  mytex = pkgs.texliveConTeXt.withPackages (
    ps: with ps; [
      fandol
      context-simpleslides
      context-notes-zh-cn
    ]
  );
  mypy = pkgs.python3.withPackages (python-pkgs: [
    python-pkgs.notmuch
  ]);

in
{

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.systemd-boot.memtest86.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;

  security.apparmor.enable = true;
  security.apparmor.killUnconfinedConfinables = true;

  # nix.settings.substituters = [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
  programs.sway.enable = true;
  programs.sway.extraSessionCommands = ''
    export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    # Fix for some Java AWT applications (e.g. Android Studio),
    # use this if they aren't displayed properly:
    export _JAVA_AWT_WM_NONREPARENTING=1

    export ELECTRON_OZONE_PLATFORM_HINT=wayland
    export QT_QPA_PLATFORM=wayland
  '';
  programs.sway.extraPackages = with pkgs; [
    foot
    swaylock
    swayidle
    grim
    adwaita-icon-theme # mouse cursor and icons
    gnome-themes-extra
    rofi-wayland
    dunst # notification daemon
    imv # simple image viewer
    i3status-rust
    wl-clipboard
    xdg-utils
  ];

  networking.hostName = "hp-840g3"; # Define your hostname.

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  services = {
    tlp = {
      enable = true;
      settings = {
        STOP_CHARGE_THRESH_BAT0 = 1;
        # treat everything as battery
        TLP_DEFAULT_MODE = "BAT";
        TLP_PERSISTENT_DEFAULT = 1;
      };
    };
    logind = {
      extraConfig = ''
        HandlePowerKey=suspend
      '';
      lidSwitch = "suspend";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "suspend";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };
  security = {
    doas.enable = true;
    sudo.enable = false;
  };

  fonts.fontconfig = {
    defaultFonts = {
      sansSerif = [
        "DejaVu Sans"
        "Noto Sans CJK SC"
      ];
      monospace = [
        "JuliaMono"
        "Noto Sans Mono CJK SC"
      ];
      serif = [
        "DejaVu Serif"
        "Noto Serif CJK SC"
      ];
    };
  };

  zramSwap.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.initrd.systemd.enable = true;

  programs.git.enable = true;

  # for trash and mtp in thunar
  services.gvfs.enable = true;

  services.davfs2 = {
    enable = true;
  };
  networking = {
    firewall.enable = true;
  };
  users.mutableUsers = false;
  services.upower.enable = true;
  programs.bash.shellInit = ''
    nixosbuildsw () {
      chown -R root /home/yc/tconf/ && nixos-rebuild switch --flake /home/yc/tconf/ && chown -R  yc /home/yc/tconf
    }
    nixosbuildbo () {
      chown -R root /home/yc/tconf/ && nixos-rebuild boot --flake /home/yc/tconf/ && chown -R  yc /home/yc/tconf
    }

  '';
  services.emacs = {
    enable = true;
    package = (
      (pkgs.emacsPackagesFor pkgs.emacs30-pgtk).emacsWithPackages (
        epkgs:
        builtins.attrValues {
          inherit (epkgs)
            # git porcelain
            magit
            # pinyin
            pyim
            pyim-basedict
            # auto complete
            counsel
            # accounting
            ledger-mode
            # emails
            notmuch
            # nix; haskell; context
            nix-ts-mode
            haskell-ts-mode
            ;
          inherit (epkgs.treesit-grammars) with-all-grammars;
        }
      )
    );
    defaultEditor = true;
    install = true;
    startWithGraphical = true;
  };
  security.chromiumSuidSandbox.enable = true;
  # show size with
  # nix path-info -rS /run/current-system | sort -nk2
  nix.gc.automatic = true;
  nix.optimise.automatic = true;
  users.users = {
    yc = {
      initialHashedPassword = "$y$j9T$S0WLvSG97zHExGCytM8L1/$wKCuLpnhARX5.ErsS9dGKpSLeTuHJ9iD3Kb/O5ZGJe4";
      description = "Yuchen Guo";
      packages =
        with pkgs;
        [
          nautilus
          qrencode
          xournalpp
          mpv
          yt-dlp
          josm
          chromium
          libreoffice
          evince
          zathura
          mupdf
          xfce.mousepad
          brightnessctl
          pavucontrol
          networkmanagerapplet
          w3m
          xarchiver
          # learn haskell and java and rust
          # c and c++
          gcc
          gnumake
          cmake
          # rust
          cargo
          rustc
          # haskell
          # https://nixos.org/manual/nixpkgs/unstable/#haskell-development-environments
          # https://haskell4nix.readthedocs.io/nixpkgs-users-guide.html#how-to-create-a-development-environment
          # https://haskell-language-server.readthedocs.io/en/latest/configuration.html#emacs
          ghc
          cabal-install
          # java; also see programs.java.enable option
          (pkgs.maven.override {
            jdk_headless = (
              pkgs.jdk.override {
                enableJavaFX = true;
              }
            );
          })
          # informatik; learn sql
          sqlite
          # end informatik
          # bookkeeping with emacs
          ledger
          # emails
          notmuch
          isync
        ]
        ++ [
          mytex
          mypy
        ];
      extraGroups = [
        # use doas
        "wheel"
        "networkmanager"
      ];
      isNormalUser = true;
    };
  };
  programs.java = {
    enable = true;
    # has wayland support
    # https://wiki.openjdk.org/display/wakefield/Pure+Wayland+toolkit+prototype
    package = (
      pkgs.jdk.override {
        enableJavaFX = true;
      }
    );
  };
  fonts.packages = builtins.attrValues {
    inherit (pkgs)
      dejavu_fonts
      babelstone-han
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      julia-mono
      font-awesome
      ;
  };
  fonts.fontconfig.localConf = ''
    <?xml version='1.0'?>
    <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
    <fontconfig>
     <dir>${mytex}/share/texmf/fonts</dir>
    </fontconfig>
  '';
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };
  i18n.defaultLocale = "en_US.UTF-8";
  programs.firefox = {
    enable = true;
  };
  # for skylake only
  hardware.graphics.extraPackages = with pkgs; [
    intel-vaapi-driver # better for skylake compat with firefox and chromium
    # intel-media-driver
  ];
  # after editing this user service and timer; re-enable them to apply changes
  # systemctl disable --user isync.service
  # systemctl enable --user isync.service
  systemd.user.services.isync = {
    description = "Free IMAP and MailDir mailbox synchronizer";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.isync}/bin/mbsync --all --quiet";
      ExecStartPost = "${pkgs.notmuch}/bin/notmuch new --decrypt=false";
      TimeoutStartSec = "360s";
    };
    path = [
      pkgs.notmuch
      mypy
    ];
  };
  systemd.user.timers.isync = {
    description = "isync timer";
    timerConfig = {
      Unit = "isync.service";
      OnCalendar = "*:0/15";
      # start immediately after computer is started:
      Persistent = "true";
    };
    wantedBy = [ "default.target" ];
  };
  programs.msmtp = {
    enable = true;
    defaults = {
      # Set default values: use the mail submission port 587, and always use TLS.
      # On this port, TLS is activated via STARTTLS.
      auth = true;
      tls = true;
      port = 587;
      tls_starttls = true;
    };
    accounts = {
      Personal = {
        host = "smtp.gmail.com";
        from = "gyuchen86@gmail.com";
        user = "gyuchen86@gmail.com";
        passwordeval = "cat /etc/pass-gmail";
      };
    };
    extraConfig = "account default : Personal";
    setSendmail = true;
  };
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ mg ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];
  # do not use hardened; interfere with amd sleep and power save
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "rtsx_pci_sdmmc"
    "thunderbolt"
    "uas"
    "sd_mod"
    "sdhci_pci"
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
