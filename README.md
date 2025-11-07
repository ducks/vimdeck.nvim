# vimdeck.nvim

A modern Neovim plugin for creating presentations from markdown files.
Inspired by the original vimdeck, rewritten from scratch using Treesitter
and native Neovim features.

![ASCII art title slide](screenshots/neovim-deck-1.png)

![Navigation slide](screenshots/neovim-deck-4.png)

## Features

- Treesitter-based markdown parsing (no external dependencies)
- ASCII art headers using figlet (h1 and h2)
- Syntax highlighted code blocks
- Support for all heading levels (h1-h6)
- Lists, blockquotes, and paragraphs
- Clean, distraction-free presentation mode
- Simple navigation with keyboard shortcuts

## Requirements

- Neovim 0.9+ (for Treesitter support)
- figlet (optional, for ASCII art headers)
- markdown Treesitter parser installed

## Installation

### Using lazy.nvim

```lua
{
  'ducks/vimdeck.nvim',
  cmd = { 'Vimdeck', 'VimdeckFile' },
  opts = {
    use_figlet = true,
    center_vertical = true,
    center_horizontal = true,
  }
}
```

### Using packer.nvim

```lua
use {
  'ducks/vimdeck.nvim',
  config = function()
    require('vimdeck').setup({
      use_figlet = true,
      center_vertical = true,
      center_horizontal = true,
    })
  end
}
```

### Install figlet

For ASCII art headers:

```bash
# macOS
brew install figlet

# Debian/Ubuntu
sudo apt install figlet

# Arch Linux
sudo pacman -S figlet

# NixOS (add to your shell.nix or configuration.nix)
pkgs.figlet
```

### Install markdown Treesitter parser

```vim
:TSInstall markdown markdown_inline
```

## Usage

### Creating Presentations

Write your presentation in markdown. Separate slides with horizontal
rules:

```markdown
# First Slide

This is the content

---

# Second Slide

More content here

---

## Last Slide

- Bullet points
- Work great
```

### Starting Presentations

From within Neovim:

```vim
# Open a markdown file and start presenting
:e presentation.md
:Vimdeck

# Or present a file directly
:VimdeckFile presentation.md
```

From Lua:

```lua
# Present current buffer
require('vimdeck').present()

# Present specific file
require('vimdeck').present_file('presentation.md')
```

### Navigation

While in presentation mode:

- Space / PageDown: Next slide
- Backspace / PageUp: Previous slide
- q / Q: Quit presentation
- gg: Jump to first slide
- G: Jump to last slide

## Markdown Support

### Headings

All heading levels (h1-h6) are supported. h1 and h2 are rendered as
ASCII art using figlet if available.

```markdown
# Big Title (ASCII art)
## Subtitle (ASCII art)
### Regular heading
```

### Code Blocks

Fenced code blocks with syntax highlighting:

````markdown
```lua
function hello()
  print("Hello!")
end
```
````

### Lists

```markdown
- Item one
- Item two
- Item three
```

### Blockquotes

```markdown
> This is a quote
> It spans multiple lines
```

## Configuration

### Global Configuration

Set global defaults in your Neovim config:

```lua
require('vimdeck').setup({
  use_figlet = true,           # Use figlet for ASCII art headers (default: true)
  center_vertical = true,      # Center slides vertically (default: true)
  center_horizontal = true,    # Center slides horizontally (default: true)
  margin = 2,                  # Horizontal margin in columns (default: 2)
  wrap = nil,                  # Text wrapping width, nil = no wrapping (default: nil)
})
```

### Per-Presentation Configuration

Override settings for individual presentations using YAML frontmatter:

```markdown
---
wrap: 80
center_horizontal: true
center_vertical: false
margin: 3
use_figlet: false
---

# First Slide

This presentation will wrap text at 80 characters, center horizontally,
start at the top, use 3-column margins, and skip ASCII art headers.
```

Frontmatter must be at the very beginning of the file, enclosed by `---` delimiters.

### Available Options

- `use_figlet` (boolean): Use figlet for ASCII art headers (h1 and h2)
- `header_style` (string): Header decoration style when figlet is disabled
  - `"underline"` - Single/double line underlines (h1 uses ═, h2 uses ─)
  - `"box"` - Simple box with ┌─┐ characters
  - `"double"` - Double-line box with ╔═╗ characters
  - `"dashed"` - Dashed underlines (h1 uses ┄, h2 uses ┈)
  - `nil` - Plain text (default)
- `center_vertical` (boolean): Center slides vertically in the window
- `center_horizontal` (boolean): Center content horizontally in the window
- `margin` (number): Horizontal margin in columns, applies even when not centering
- `wrap` (number): Wrap long lines at specified character width (useful for prose)

## Differences from Original vimdeck

The original vimdeck was a Ruby script that generated temporary files.
This plugin:

- Is a native Neovim plugin (no external script needed)
- Uses Treesitter for accurate markdown parsing
- Renders slides dynamically (no temp files)
- Leverages Neovim's built-in syntax highlighting
- Supports all markdown heading levels
- Faster and more integrated with Neovim

## Screenshots

<details>
<summary>Click to view screenshots</summary>



### Code Examples
![Code block slide](screenshots/neovim-deck-2.png)

### Lists and Formatting
![Lists slide](screenshots/neovim-deck-3.png)

### Final Slide
![Thank you slide](screenshots/neovim-deck-5.png)

</details>

## Examples

See `example.md` for a sample presentation.

## License

MIT

## Credits

Inspired by the original vimdeck by Tyler Benziger.
