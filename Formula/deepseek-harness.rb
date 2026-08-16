# Installs the official npm build of the DeepSeek Harness CLI (`dsh`).
#
# The published package `@deepseek-ai/dsh` is the compiled artifact of this
# repository's `apps/cli` workspace, so installing it avoids a full monorepo
# build (tsc + tsdown across ~100 workspaces plus the Vite web frontend).
#
# `dsh web` serves the DeepSeek Harness browser UI (default
# http://127.0.0.1:3080) and is registered as a launchd service so it can be
# managed with `brew services start|stop|restart deepseek-harness`.

class DeepseekHarness < Formula
  desc "Everything is a plugin: the dsh CLI and DeepSeek Harness Web UI server"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.0-rc.6.tgz"
  sha256 "1b8a9a0ad3c7feaece47926e0bd37ca151c7ccfa997953afa5fd01261784eadc"
  license "MIT"

  depends_on "node"

  def install
    # Homebrew's extractor strips the npm tarball's single `package/` root.
    libexec.install Dir["*"]
    chmod 0755, libexec/"lib/bin.js"
    # std_npm_args passes --min-release-age=14, which refuses packages
    # published within the last 14 days; dsh ships rolling -rc releases, so
    # install the dependency tree with plain npm flags instead.
    npm_install_args = ["npm", "install", "--omit=dev", "--no-audit",
                        "--no-fund", "--no-update-notifier", "--prefix", libexec]
    system(*npm_install_args)
    # node-pty's install script also downloads x86_64 darwin prebuilds on
    # Apple Silicon; drop them so the prefix only contains native binaries.
    rm_r libexec/"node_modules/node-pty/prebuilds/darwin-x64" if Hardware::CPU.arm?
    # node-pty's npm prebuilds ship the macOS spawn-helper WITHOUT the
    # executable bit (upstream packaging bug), so every PTY spawn fails with
    # "posix_spawnp failed." — the minimal agent preset's persistent shell
    # is PTY-only and breaks entirely. npm extraction preserves the tarball
    # mode (0644), so restore +x for the installed darwin arch here.
    chmod 0755, libexec/"node_modules/node-pty/prebuilds/darwin-arm64/spawn-helper" if Hardware::CPU.arm?
    chmod 0755, libexec/"node_modules/node-pty/prebuilds/darwin-x64/spawn-helper" if Hardware::CPU.intel?
    node_bin = formula_opt_bin("node")
    (bin/"dsh").write_env_script(
      libexec/"lib/bin.js",
      PATH: "#{node_bin}:#{HOMEBREW_PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    )
  end

  def caveats
    <<~EOS
      `dsh web` serves the DeepSeek Harness browser UI at http://127.0.0.1:3080.

      Start it as a login service (auto-start at login, auto-restart on crash):
        brew services start deepseek-harness

      Status and stop:
        brew services info deepseek-harness
        brew services stop deepseek-harness

      Run once in the foreground instead:
        dsh web

      Override the listen port (e.g. 8080):
        dsh web --port 8080

      Logs: #{var}/log/dsh.log
      Profiles and data: ~/.dsh (set $DSH_HOME to relocate)
      The `dsh plugin` subcommand also needs pnpm: brew install pnpm
    EOS
  end

  test do
    assert_match "dsh", shell_output("#{bin}/dsh --help")
    assert_match "Serve the DeepSeek Harness browser UI",
                 shell_output("#{bin}/dsh web --help")
  end

  service do
    run [opt_bin/"dsh", "web"]
    keep_alive true
    require_root false
    working_dir HOMEBREW_PREFIX
    log_path var/"log/dsh.log"
    error_log_path var/"log/dsh.log"
    environment_variables PATH: "#{HOMEBREW_PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  end
end
