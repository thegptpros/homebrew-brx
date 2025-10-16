# 🍺 Create Your Own Homebrew Tap for BRX

## 🎯 What You'll Create

A Homebrew tap that lets users install BRX with:
```bash
brew tap thegptpros/brx
brew install brx
```

---

## 📋 Step-by-Step Setup (10 minutes)

### **Step 1: Create Homebrew Tap Repository (2 min)**

```bash
# Create a new GitHub repo named: homebrew-brx
# URL will be: https://github.com/thegptpros/homebrew-brx

# Clone it
cd ~/Desktop/code
git clone https://github.com/thegptpros/homebrew-brx.git
cd homebrew-brx

# Create Formula directory
mkdir -p Formula
```

**Important:** Homebrew requires the repo name to start with `homebrew-`

---

### **Step 2: Create Release Binary (5 min)**

```bash
cd /Users/zac/Desktop/code/brx

# Build release binary
make build

# Create release archive
VERSION=3.0.0
tar -czf brx-${VERSION}-macos.tar.gz -C .build/release BRX

# Calculate SHA256
shasum -a 256 brx-${VERSION}-macos.tar.gz
# Copy this hash - you'll need it!

# Upload to GitHub releases
# Go to: https://github.com/thegptpros/brx/releases
# Create new release: v3.0.0
# Upload: brx-3.0.0-macos.tar.gz
# Copy the download URL
```

---

### **Step 3: Create Homebrew Formula (3 min)**

Create `Formula/brx.rb`:

```ruby
class Brx < Formula
  desc "Build, run, and ship iOS apps from your terminal"
  homepage "https://brx.dev"
  url "https://github.com/thegptpros/brx/releases/download/v3.0.0/brx-3.0.0-macos.tar.gz"
  sha256 "YOUR_SHA256_HASH_HERE"
  version "3.0.0"
  license "Proprietary"

  def install
    bin.install "BRX" => "brx"
    
    # Install templates
    (prefix/"Templates").install Dir["Templates/*"] if Dir.exist?("Templates")
    
    # Create symlink for templates
    (buildpath/"Templates").install_symlink prefix/"Templates"
  end

  def caveats
    <<~EOS
      ◻︎ brx — build. run. ship. ios. from terminal.

      Get started:
        brx activate --license-key <YOUR-KEY>
        brx build --name MyApp
        brx run

      Purchase a license: https://brx.dev
      Documentation: https://brx.dev/docs
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/brx --version")
  end
end
```

---

### **Step 4: Push to GitHub**

```bash
cd ~/Desktop/code/homebrew-brx

git add Formula/brx.rb
git commit -m "Add BRX formula v3.0.0"
git push origin main
```

---

### **Step 5: Test Installation**

```bash
# Tap your repository
brew tap thegptpros/brx

# Install BRX
brew install brx

# Verify
brx --version
# Should show: 3.0.0

# Test
brx
# Should show your beautiful menu!
```

---

## 🔄 **Update Process (For Future Releases)**

```bash
# 1. Build new version
cd /Users/zac/Desktop/code/brx
# Update version in BRXMain.swift
make build

# 2. Create release archive
VERSION=3.0.1
tar -czf brx-${VERSION}-macos.tar.gz -C .build/release BRX
shasum -a 256 brx-${VERSION}-macos.tar.gz

# 3. Create GitHub release
# Upload tar.gz to: https://github.com/thegptpros/brx/releases

# 4. Update Homebrew formula
cd ~/Desktop/code/homebrew-brx
nano Formula/brx.rb

# Update:
# - version "3.0.1"
# - url "...v3.0.1/brx-3.0.1-macos.tar.gz"
# - sha256 "NEW_HASH"

git commit -am "Bump to v3.0.1"
git push

# 5. Users upgrade with:
brew update
brew upgrade brx
```

---

## 🚀 **Advanced: Include Templates**

To include your templates in the Homebrew installation:

```ruby
# In Formula/brx.rb
def install
  bin.install "BRX" => "brx"
  
  # Install templates to Homebrew prefix
  (share/"brx/Templates").install Dir["Templates/*"]
end
```

Update BRX to look for templates at:
```swift
// In BuildCommand.swift
"/opt/homebrew/share/brx/Templates/\(name)" // Apple Silicon
"/usr/local/share/brx/Templates/\(name)"   // Intel
```

---

## 📦 **Complete Installation Command**

Once set up, users run:

```bash
brew tap thegptpros/brx
brew install brx
brx activate --license-key <KEY>
brx build --name MyApp
```

**That's it!** Professional Homebrew installation! 🍺

---

## 🎯 **What You Need**

1. ✅ Create `homebrew-brx` repo on GitHub
2. ✅ Create release on `thegptpros/brx` with tar.gz
3. ✅ Create `Formula/brx.rb` with correct SHA256
4. ✅ Push to `homebrew-brx` repo
5. ✅ Test installation

**Time:** 10 minutes
**Difficulty:** Easy!

---

## 📚 **Resources**

- Homebrew Formula Cookbook: https://docs.brew.sh/Formula-Cookbook
- GitHub Releases: https://github.com/thegptpros/brx/releases
- Your tap: https://github.com/thegptpros/homebrew-brx

**Ready to create your Homebrew tap?** 🍺✨

