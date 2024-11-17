class KubesealUtils < Formula
  desc "Command line utility for working with Kubernetes sealed secrets"
  homepage "https://github.com/joseph-ravenwolfe/kubeseal-utils"
  url "https://github.com/joseph-ravenwolfe/homebrew-kubeseal-utils/archive/v0.2.0.tar.gz"
  sha256 "9c36a6eba485af964a8767f461f8413452944cfa3c658ab21f3936d37037dfde"
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