from snapper_api import config


def test_dotenv_loads_quoted_token_without_overriding_deployment_value(tmp_path, monkeypatch):
    monkeypatch.setattr(config, "__file__", str(tmp_path / "snapper_api" / "config.py"))
    (tmp_path / ".env").write_text('DISCOGS_TOKEN="local token with spaces"\n')

    monkeypatch.delenv("DISCOGS_TOKEN", raising=False)
    assert config.discogs_token() == "local token with spaces"

    monkeypatch.setenv("DISCOGS_TOKEN", "production-token")
    assert config.discogs_token() == "production-token"
