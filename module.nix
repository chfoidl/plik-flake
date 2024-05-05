inputs : { config, lib, pkgs, ... }: let
  inherit (pkgs.stdenv.hostPlatform) system;

  package = inputs.self.packages.${system}.plik;

  cfg = config.services.plik;

  dataDir = "/var/lib/plik";
in {
  options = {
    services.plik = {
      enable = lib.mkEnableOption (lib.mdDoc "Plik file sharing");

      user = lib.mkOption {
        type = lib.types.str;
        default = "plik";
        description = lib.mdDoc "User account under which plik runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "plik";
        description = lib.mdDoc "Group under which plik runs.";
      };

      configFile = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc "Config file contents.";
        default = ''
          Debug               = false            # Enable debug mode
          DebugRequests       = false            # Log HTTP request and responses
          LogLevel            = "INFO"           # Log level (DEBUG|INFO|WARNING|CRITICAL)

          ListenPort          = 8080             # Port the HTTP server will listen on
          ListenAddress       = "127.0.0.1"        # Address the HTTP server will bind on
          MetricsPort         = 0                # Port the HTTP metrics server will listen on (0 = disabled)
          MetricsAddress      = "127.0.0.1"        # Address the HTTP server will bind on
          Path                = ""               # HTTP root path
          SslEnabled          = false            # Enable SSL
          SslCert             = "plik.crt"       # Path to your certificate file
          SslKey              = "plik.key"       # Path to your certificate private key file
          TlsVersion          = "tlsv10"         # TLS version (tlsv10|tlsv11|tlsv12|tlsv13)
          NoWebInterface      = false            # Disable web user interface
          DownloadDomain      = ""               # Enforce download domain ( ex : https://dl.plik.root.gg ) ( necessary for quick upload to work )
          DownloadDomainAlias = []               # Set download domain aliases ( ex : ["http://localhost:8080","http://127.0.0.1:8080"] ) ( must config a DownloadDomain first )
          EnhancedWebSecurity = false            # Enable additional security headers ( X-Content-Type-Options, X-XSS-Protection, X-Frame-Options, Content-Security-Policy, Secure Cookies, ... )
          SessionTimeout      = "365d"           # Web UI authentication session timeout (https://chromestatus.com/feature/4887741241229312)
          AbuseContact        = ""               # Abuse contact to be displayed in the footer of the webapp ( email address )
          WebappDirectory     = "${package}/webapp/dist" # Root directory for webapp static content
          ClientsDirectory    = "${package}/clients"     # Root directory for client binaries
          ChangelogDirectory  = "${package}/changelog"   # Root directory for changelog (to be displayed when updating clients)
          SourceIpHeader      = ""               # If behind reverse proxy ( ex : X-FORWARDED-FOR )
          UploadWhitelist     = []               # Restrict upload and user creation to one or more IP range ( CIDR notation, /32 can be omitted )

          MaxFileSizeStr      = "20GB"           # 10GB (or "unlimited")
          MaxUserSizeStr      = "unlimited"      # Default max uploaded size per user unless configured otherwise (or "unlimited")
          MaxFilePerUpload    = 1000

          DefaultTTLStr       = "30d"            # 30 days
          MaxTTLStr           = "30d"            # 0 : No limit

# Feature flags to enable/disable Plik features.
#  - disabled : feature is always off
#  - enabled  : feature is opt-in
#  - default  : feature is opt-out
#  - forced   : feature is always on
          FeatureAuthentication = "forced"     # disabled -> no authentication / forced -> no anonymous upload / default -> enabled
          FeatureOneShot        = "enabled"      # Upload with files that are automatically deleted after the first download
          FeatureRemovable      = "enabled"      # Upload with files that anybody can delete
          FeatureStream         = "enabled"      # Upload with files that are not stored on the server
          FeaturePassword       = "enabled"      # Upload that are protected by HTTP basic auth login/password
          FeatureComments       = "enabled"      # Upload with markdown comments / forced -> default
          FeatureSetTTL         = "enabled"      # When disabled upload TTL is always set to DefaultTTL
          FeatureExtendTTL      = "disabled"     # Extend upload expiration date by TTL each time it is accessed
          FeatureClients        = "enabled"      # Display the clients download button in the web UI
          FeatureGithub         = "enabled"      # Display the source code link in the web UI
          FeatureText           = "enabled"      # Upload text dialog

          GoogleApiClientID   = ""               # Google api client ID
          GoogleApiSecret     = ""               # Google api client secret
          GoogleValidDomains  = []               # List of acceptable email domains for users
          OvhApiKey           = ""               # OVH api application key
          OvhApiSecret	    = ""               # OVH api application secret
          OvhApiEndpoint      = ""               # OVH api endpoint to use. Defaults to https://eu.api.ovh.com/1.0

          DataBackend = "file"
          [DataBackendConfig]
              Directory = "${dataDir}/files"

          [MetadataBackendConfig]
              Driver = "sqlite3"
              ConnectionString = "${dataDir}/plik.db"
              Debug = false # Log SQL requests
        '';
      };
    };
  };

  # Implemetation.

  config = lib.mkIf cfg.enable {

    systemd.services.plik = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${package}/bin/plikd";
        Restart = "on-failure";
        StateDirectory = baseNameOf dataDir;
        User = "${cfg.user}";
        Group = "${cfg.group}";
      };
    };

    environment.etc."plikd.cfg" = {
      text = cfg.configFile;
      user = cfg.user;
      group = cfg.user;
      mode = "0440";
    };

    systemd.tmpfiles.rules = [
      "d '${dataDir}' 0700 '${cfg.user}' - - -"
    ];

    users.users = lib.mkIf (cfg.user == "plik") {
      plik = {
        description = "plik user";
        isSystemUser = true;
        group = cfg.group;
      };
    };

    users.groups = lib.mkIf (cfg.group == "plik") { plik = { }; };

  };

}


