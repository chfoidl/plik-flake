{
  fetchurl,
  version,
}: {
  x86_64-linux = fetchurl {
    url = "https://github.com/root-gg/plik/releases/download/${version}/plik-${version}-linux-amd64.tar.gz";
    hash = "sha256-taUFXZJeUHYjjhrVlLgKYPxNn6W5o8uoEVcu+f5flCA=";
  };
  aarch64-linux = fetchurl {
    url = "https://github.com/root-gg/plik/releases/download/${version}/plik-${version}-linux-arm64.tar.gz";
    hash = "sha256-mW+7rGcYBC6aZW/7KwKWPnlmMHwe+enk5f6r+m0jZng=";
  };
}

