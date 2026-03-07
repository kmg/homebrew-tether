class Tether < Formula
  desc "Mobile tmux monitor with Claude Code activity detection"
  homepage "https://github.com/kmg/tether"
  version "0.1.20"
  license "MIT"

  url "https://github.com/kmg/tether/releases/download/v#{version}/tether-#{version}-aarch64-apple-darwin.tar.gz"
  sha256 "5e13c93dfbbf40c585e8df4928e5431ea28bb52b196db50b45aa3291576be827"

  depends_on "tmux"
  depends_on arch: :arm64
  depends_on :macos

  def install
    # The release tarball extracts to a flat structure with bin/, lib/, releases/
    libexec.install Dir["*"]

    # Create wrapper script
    (bin/"tether").write <<~SH
      #!/bin/bash
      # Tether - Mobile tmux monitor
      # https://github.com/kmg/tether

      export TETHER_DATA_DIR="${TETHER_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/tether}"
      export RELEASE_COOKIE="${RELEASE_COOKIE:-$(cat "$TETHER_DATA_DIR/.cookie" 2>/dev/null || echo "tether")}"

      case "$1" in
        start)
          exec "#{libexec}/bin/tether" start
          ;;
        daemon)
          exec "#{libexec}/bin/tether" daemon
          ;;
        stop)
          exec "#{libexec}/bin/tether" stop
          ;;
        status)
          "#{libexec}/bin/tether" pid 2>/dev/null && echo "Tether is running" || echo "Tether is not running"
          ;;
        remote)
          exec "#{libexec}/bin/tether" remote
          ;;
        setup-push)
          exec "#{libexec}/bin/tether" eval 'keys = Tether.Notifier.generate_vapid_keys(); IO.puts("VAPID_PUBLIC_KEY=\#{keys.public_key}\nVAPID_PRIVATE_KEY=\#{keys.private_key}")'
          ;;
        version)
          echo "Tether v#{version}"
          ;;
        *)
          echo "Usage: tether {start|daemon|stop|status|remote|setup-push|version}"
          echo ""
          echo "Commands:"
          echo "  start       Start Tether in the foreground"
          echo "  daemon      Start Tether as a background daemon"
          echo "  stop        Stop a running daemon"
          echo "  status      Check if Tether is running"
          echo "  remote      Attach a remote IEx shell"
          echo "  setup-push  Generate VAPID keys for push notifications"
          echo "  version     Print version"
          exit 1
          ;;
      esac
    SH
  end

  service do
    run [opt_bin/"tether", "start"]
    keep_alive true
    log_path var/"log/tether.log"
    error_log_path var/"log/tether.log"
    working_dir HOMEBREW_PREFIX
  end

  def caveats
    <<~EOS
      Tether is installed! Quick start:

        tether start

      Then open the URL printed in your terminal (includes auth token).

      To run as a background service:

        brew services start tether

      Configure via env file (no shell profile edits needed):

        ~/.local/share/tether/env

      For push notifications, generate VAPID keys:

        tether setup-push >> ~/.local/share/tether/env
        brew services restart tether

      Data is stored in: ~/.local/share/tether/
      Logs (when using brew services): #{var}/log/tether.log
    EOS
  end

  test do
    assert_match "Tether v#{version}", shell_output("#{bin}/tether version")
  end
end
