# Shlande Tap

## Formulae

### deepseek-harness

The [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) CLI
(`dsh`) and its Web UI server, packaged as a launchd service.

```sh
brew install shlande/tap/deepseek-harness

# run the browser UI as a login service (auto-start at login, auto-restart on crash)
brew services start deepseek-harness   # -> http://127.0.0.1:3080
brew services stop deepseek-harness

# or run once in the foreground
dsh web --port 8080
```

## How do I install these formulae?

`brew install shlande/tap/<formula>`

Or `brew tap shlande/tap` and then `brew install <formula>`.

Or, in a `brew bundle` `Brewfile`:

```ruby
tap "shlande/tap"
brew "<formula>"
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
