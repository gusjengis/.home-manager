{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.secrets.anthropicApiKey = lib.mkOption {
    type = lib.types.str;
    description = "Anthropic API Key";
  };

  config.secrets.anthropicApiKey = "paste key here";
}
