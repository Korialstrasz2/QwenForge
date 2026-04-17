from urllib.parse import urlparse


LOCAL_HOSTS = {"localhost", "127.0.0.1", "0.0.0.0", "::1", "host.docker.internal"}


def is_local_endpoint(url: str) -> bool:
    parsed = urlparse(url)
    host = (parsed.hostname or "").lower()
    return host in LOCAL_HOSTS


def require_local_endpoint(url: str, *, all_local_mode: bool) -> None:
    if all_local_mode and not is_local_endpoint(url):
        raise ValueError(
            "All-local mode is enabled. Configure a local inference endpoint "
            "(localhost/127.0.0.1/host.docker.internal)."
        )
