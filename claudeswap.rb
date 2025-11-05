class Claudeswap < Formula
  desc "Safely swap between GLM providers (Z.ai), MiniMax, and standard Anthropic Claude configurations with dynamic model mapping and performance optimization"
  homepage "https://github.com/sachicali/homebrew-claudeswap"
  version "1.2.2"
  license "MIT"

  url "https://github.com/sachicali/homebrew-claudeswap/archive/refs/tags/v1.2.2.tar.gz"
  sha256 "0f12fe118b0441d39f8b28ea84fe4daaa42425e33549a0e313c9c088e76961d4"

  depends_on "jq"
  depends_on "curl"

  def install
    # Install the main script
    bin.install "claudeswap"

    # Create lib directory in the formula's libexec
    (libexec/"lib").install Dir["lib/**/*"]

    # Make all lib files executable
    Dir["#{libexec}/lib/**/*.sh"].each do |sh|
      File.chmod(0755, sh)
    end

    # Install the zsh completion file
    zsh_completion.install "claudeswap.zsh" => "_claudeswap"

    # Install documentation
    doc.install "README.md"
    doc.install "LICENSE"
    doc.install "SETUP-GUIDE.md"
    doc.install "example-configs.md"
  end

  test do
    # Test that the script runs and shows help
    assert_match "Usage: claudeswap", shell_output("#{bin}/claudeswap help")
  end
end
