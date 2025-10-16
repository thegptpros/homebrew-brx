class Brx < Formula
  desc "Build, run, and ship iOS apps from your terminal"
  homepage "https://brx.dev"
  url "https://github.com/thegptpros/brx/releases/download/v3.0.0/brx-3.0.0-macos.tar.gz"
  sha256 "125eddb9beb161ef28bfb110db6a794751b5a977699b1c18f3732b88dd106bc1"
  version "3.0.0"
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

      BRX requires a valid license to use.
      
      Get started:
        brx activate --license-key <YOUR-KEY>
        brx build --name MyApp
        brx run

      Purchase a license at: https://brx.dev
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

