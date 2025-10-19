class Brx < Formula
  desc "Build, run, and ship iOS apps from your terminal"
  homepage "https://brx.dev"
  url "https://github.com/thegptpros/homebrew-brx/releases/download/v3.1.5/brx-3.1.5-macos.tar.gz"
  sha256 "75b7b2abae2d9b9e2706c688060423b63cf52988764c78f159451bfe22e434dd"
  version "3.1.5"
  license "Proprietary"

  # Requires macOS and Xcode
  depends_on :macos
  depends_on xcode: ["15.0", :build]

  def install
    # Install the main binary
    bin.install "BRX" => "brx"
    
    # Install templates to share directory
    if Dir.exist?("Templates")
      (share/"brx/Templates").install Dir["Templates/*"]
    end
  end

  def caveats
    <<~EOS
      ◻︎ brx — build. run. ship. ios. from terminal.

      Try BRX FREE with 3 builds, then activate for unlimited:
      
      Get started:
        brx build --name MyApp
        brx run
      
      After 3 free builds, activate for unlimited:
        brx activate --license-key <YOUR-KEY>

      Get a license at: https://brx.dev
      Documentation: https://brx.dev/docs
      
      Templates installed to:
        #{HOMEBREW_PREFIX}/share/brx/Templates
    EOS
  end

  test do
    # Test that binary runs
    system "#{bin}/brx", "--version"
  end
end

