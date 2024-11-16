class KubesealUtils < Formula
  desc "Command line utility for working with Kubernetes sealed secrets"
  homepage "https://github.com/joseph-ravenwolfe/kubeseal-utils"
  url "https://github.com/joseph-ravenwolfe/homebrew-kubeseal-utils/archive/v0.1.0.tar.gz"
  sha256 "99cf37749287f0e975aa633871fef39b00f7f709ff1ae4a62be835e05669d19f"
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