# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.systemd-boot.memtest86.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;

  services.logrotate.checkConfig = false;
  environment.memoryAllocator.provider = "libc";
  security.lockKernelModules = false;

  # must allow simulaneous multithreading for sleep/suspend to work on amd
  security.allowSimultaneousMultithreading = true;

  security.unprivilegedUsernsClone = true;

  nix.settings.substituters = [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
  programs.sway.enable = true;
  programs.sway.extraPackages = with pkgs; [
    foot
    wmenu
    swaylock
    swayidle
    i3status
    brightnessctl
    wl-clipboard
    grim
    gnome.adwaita-icon-theme
    gnome.gnome-themes-extra
  ];
  programs.sway.extraSessionCommands = ''
    export ELECTRON_OZONE_PLATFORM_HINT=wayland
  '';
  networking.hostName = "yinzhou"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  services = {
    yggdrasil = {
      enable = true;
      openMulticastPort = false;
      extraArgs = [
        "-loglevel"
        "error"
      ];
      settings.Peers =
        #curl -o test.html https://publicpeers.neilalexander.dev/
        # grep -e 'tls://' -e 'tcp://' -e 'quic://' test.html | grep online | sed 's|<td id="address">|"|' | sed 's|</td><td.*|"|g' | sort | wl-copy -n
        (import ../yggdrasil-peers.nix);
    };
    tlp = {
      enable = true;
      settings = {
        DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wwan";
        STOP_CHARGE_THRESH_BAT0 = 1;
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        CPU_BOOST_ON_BAT = 0;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
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
  programs.tmux = {
    enable = true;
    keyMode = "emacs";
    newSession = true;
    terminal = "tmux-direct";
    extraConfig = ''
      unbind C-b
      unbind f7
      set -u prefix
      set -g prefix f7
      bind -N "Send the prefix key" f7 send-prefix
    '';
  };
  fonts.fontconfig = {
    defaultFonts = {
      sansSerif = [
        "DejaVu Sans"
        "Noto Sans CJK SC"
      ];
      monospace = [
        "JuliaMono"
        "DejaVu Sans Mono"
        "Noto Sans Mono CJK SC"
      ];
      serif = [
        "DejaVu Serif"
        "Noto Sans CJK SC"
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
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
  };
  networking = {
    firewall.enable = true;
  };
  users.mutableUsers = false;
  users.users = {
    yc = {
      initialHashedPassword = "$6$UxT9KYGGV6ik$BhH3Q.2F8x1llZQLUS1Gm4AxU7bmgZUP7pNX6Qt3qrdXUy7ZYByl5RVyKKMp/DuHZgk.RiiEXK8YVH.b2nuOO/";
      description = "Yuchen Guo";
      packages = with pkgs; [
        qrencode
        xournalpp
        mpv
        yt-dlp
        zathura
        pulseaudio
        gpxsee
        proxychains-ng
        autossh
        ((pkgs.emacsPackagesFor pkgs.emacs-nox).emacsWithPackages (
          epkgs:
          builtins.attrValues {
            inherit (epkgs)
              nix-mode
              magit
              pyim
              pyim-basedict
              ;
            inherit (epkgs.treesit-grammars) with-all-grammars;
          }
        ))
        (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]))
      ];
      extraGroups = [
        # use doas
        "wheel"
      ];
      isNormalUser = true;
    };
  };
  fonts.packages = builtins.attrValues {
    inherit (pkgs)
      dejavu_fonts
      noto-fonts-cjk-sans
      gyre-fonts
      stix-two
      julia-mono
      ;
  };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };
  i18n.defaultLocale = "en_US.UTF-8";
  programs.firefox = {
    enable = true;
    policies = {
      "3rdparty" = {
        Extensions = {
          # name must be the same as above
          "uBlock0@raymondhill.net" = {
            adminSettings = {
              userSettings = {
                advancedUserEnabled = true;
                popupPanelSections = 31;
              };
              dynamicFilteringString = ''
                * * inline-script block
                * * 1p-script block
                * * 3p-script block
                * * 3p-frame block'';
              hostnameSwitchesString = ''
                no-cosmetic-filtering: * true
                no-remote-fonts: * true
                no-csp-reports: * true
                no-scripting: * true
              '';
            };
          };
        };
      };
      DisableBuiltinPDFViewer = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisplayMenuBar = "never";
      DNSOverHTTPS = {
        Enabled = false;
      };
      DontCheckDefaultBrowser = true;
      ExtensionUpdate = false;
      Extensions = {
        Install = [ ("file://" + ./umatrix-1.4.4.xpi) ];
      };
      FirefoxHome = {
        Search = false;
        TopSites = false;
        Highlights = false;
        Snippets = false;
        SponsoredTopSites = false;
        Pocket = false;
        SponsoredPocket = false;
      };
      FirefoxSuggest = {
        SponsoredSuggestions = false;
      };
      HardwareAcceleration = true;
      Homepage = {
        StartPage = "none";
      };
      NetworkPrediction = false;
      NewTabPage = false;
      NoDefaultBookmarks = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      PDFjs = {
        Enabled = false;
      };
      Permissions = {
        Notifications = {
          BlockNewRequests = true;
        };
      };
      PictureInPicture = {
        Enabled = false;
      };
      PopupBlocking = {
        Default = false;
      };
      PromptForDownloadLocation = true;
      SearchSuggestEnabled = false;
      ShowHomeButton = true;
      UserMessaging = {
        WhatsNew = false;
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        MoreFromMozilla = false;
        SkipOnboarding = true;
      };
    };
    preferences = {
      "browser.aboutConfig.showWarning" = false;
      "browser.backspace_action" = 0;
      "browser.chrome.site_icons" = false;
      "browser.display.use_document_fonts" = 0;
      "browser.tabs.firefox-view" = false;
      "browser.tabs.inTitlebar" = 0;
      "browser.uidensity" = 1;
      "general.smoothScroll" = false;
      "media.ffmpeg.vaapi.enabled" = true;
      "media.navigator.mediadatadecoder_vpx_enabled" = true;
      "network.IDN_show_punycode" = true;
      "dom.security.https_only_mode" = true;
      "widget.wayland.opaque-region.enabled" = false;
    };
    preferencesStatus = "default";
    autoConfig = ''
      pref("apz.allow_double_tap_zooming", false);
      pref("apz.allow_zooming", false);
      pref("apz.gtk.touchpad_pinch.enabled", false);
      pref("font.name-list.emoji", "Noto Color Emoji");
    '';
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
  environment.systemPackages = with pkgs; [
    mg
    # create secure boot keys
    sbctl
    powertop
  ];

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
}
