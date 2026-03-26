# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Certs do
  @moduledoc """
  Auto-generates self-signed TLS certificates for the mock server.

  When HTTPS is enabled (the default) but no certificate files exist,
  this module generates a self-signed certificate using `openssl`.
  The generated PEM files are written to the configured cert directory
  (default: `certs/`).
  """

  require Logger

  @default_keyfile "certs/server.key"
  @default_certfile "certs/server.crt"

  @doc """
  Ensures TLS certificate files exist, generating them if necessary.

  Returns `{keyfile, certfile}` with absolute paths.
  """
  @spec ensure_certs(String.t(), String.t()) :: {String.t(), String.t()}
  def ensure_certs(keyfile \\ @default_keyfile, certfile \\ @default_certfile) do
    keyfile = Path.expand(keyfile)
    certfile = Path.expand(certfile)

    if File.exists?(keyfile) and File.exists?(certfile) do
      Logger.debug("Using existing TLS certificates: #{certfile}")
    else
      Logger.info("Auto-generating self-signed TLS certificates...")
      generate(keyfile, certfile)
      Logger.info("TLS certificates written to #{Path.dirname(certfile)}/")
    end

    {keyfile, certfile}
  end

  defp generate(keyfile, certfile) do
    dir = Path.dirname(keyfile)
    File.mkdir_p!(dir)

    # Generate RSA key + self-signed cert in one openssl command
    {_, 0} =
      System.cmd("openssl", [
        "req",
        "-x509",
        "-newkey",
        "rsa:2048",
        "-keyout",
        keyfile,
        "-out",
        certfile,
        "-days",
        "365",
        "-nodes",
        "-subj",
        "/CN=localhost/O=Mock PVE API",
        "-addext",
        "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:::1"
      ])

    File.chmod!(keyfile, 0o600)
    File.chmod!(certfile, 0o644)
  end
end
