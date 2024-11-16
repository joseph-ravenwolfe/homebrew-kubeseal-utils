class KubesealUtils < Formula
  desc "Command line utility for working with Kubernetes sealed secrets"
  homepage "https://github.com/joseph-ravenwolfe/kubeseal-utils"
  url "https://github.com/joseph-ravenwolfe/homebrew-kubeseal-utils/archive/v0.1.1.tar.gz"
  sha256 "cc4380c50f6f8b665287449591070eedb0e9bae8037fe55e52b6b1b17d33cf44"
  license "MIT"

  depends_on "jq"
  depends_on "yq"
  depends_on "kubeseal"
  depends_on "mfuentesg/tap/ksd"
  depends_on "fzf"

  def install
    bin.install "bin/kubeseal-utils"
  end

  test do
    output = shell_output("#{bin}/kubeseal-utils --help", 1)
    assert_match "Usage:", output
  end
end