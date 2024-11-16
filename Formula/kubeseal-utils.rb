class KubesealUtils < Formula
  desc "Command line utility for working with Kubernetes sealed secrets"
  homepage "https://github.com/joseph-ravenwolfe/kubeseal-utils"
  url "https://github.com/joseph-ravenwolfe/kubeseal-utils/archive/v0.1.0.tar.gz"
  sha256 "THE_SHA_256_OF_YOUR_RELEASE_TARBALL"
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
    assert_match "Command line utility for working with Kubernetes sealed secrets",
                 shell_output("#{bin}/kubeseal-utils --help")
  end
end