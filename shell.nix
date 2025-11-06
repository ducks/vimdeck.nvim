{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Lua language server for development
    lua-language-server

    # Lua for standalone testing/scripting
    lua5_1

    # luarocks for any Lua dependencies
    luarocks

    # figlet for ASCII art generation
    figlet

    # For image-to-ASCII conversion (if we want it)
    imagemagick
  ];

  shellHook = ''
    echo "🎨 vimdeck.nvim development environment"
    echo ""
    echo "Available tools:"
    echo "  lua $(lua -v)"
    echo "  lua-language-server $(lua-language-server --version)"
    echo "  figlet $(figlet -v 2>&1 | head -n1)"
    echo ""
    echo "Plugin structure:"
    echo "  lua/vimdeck/     - Core Lua code"
    echo "  plugin/          - Plugin initialization"
    echo "  doc/             - Documentation"
    echo ""
    echo "Test your plugin:"
    echo "  nvim -u NONE -c 'set rtp+=.' -c 'runtime plugin/vimdeck.lua' test.md"
  '';
}
