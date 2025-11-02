class ClaudeSwap < Formula
  desc "Safely swap between Z.ai, MiniMax, and standard Anthropic Claude configurations"
  homepage "https://github.com/chicali/claude-swap"
  version "1.0.0"
  license "MIT"

  if OS.mac?
    url "https://github.com/chicali/claude-swap/archive/refs/tags/v1.0.0.tar.gz"
    sha256 "TODO_GET_SHA256_AFTER_CREATING_TAG"
  end

  depends_on "jq"

  def install
    # Install the main script
    bin.install "claude-swap"

    # Install the zsh completion file
    zsh_completion.install "claude-swap.zsh" => "_claude-swap"

    # Install documentation
    doc.install "README.md"
    doc.install "LICENSE"
    
    # Create example config files
    (pkgshare/"examples").install "example-configs.md"
  end

  test do
    # Test that the script runs
    assert_match "Usage: claude-swap", shell_output("#{bin}/claude-swap help")
  end
end
