import httpx2

RETRYABLE_STATUS_CODES = {408, 429, 500, 502, 503, 504}

RETRYABLE_EXCEPTIONS = (
    httpx2.ConnectTimeout,
    httpx2.ConnectError,
    httpx2.ReadTimeout,
    httpx2.ReadError,
    httpx2.WriteTimeout,
    httpx2.WriteError,
    httpx2.RemoteProtocolError,
)


def is_retryable(exc: BaseException) -> bool:
    if isinstance(exc, RETRYABLE_EXCEPTIONS):
        return True

    if isinstance(exc, httpx2.HTTPStatusError):
        return exc.response.status_code in RETRYABLE_STATUS_CODES

    return False
