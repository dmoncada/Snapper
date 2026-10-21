from typing import Annotated

from fastapi import Depends, Request

from app.providers.discogs.client import DiscogsClient
from app.providers.itunes.client import ItunesClient


def get_discogs_client(request: Request) -> DiscogsClient:
    return request.app.state.discogs


def get_itunes_client(request: Request) -> ItunesClient:
    return request.app.state.itunes


DiscogsClientDep = Annotated[DiscogsClient, Depends(get_discogs_client)]
ItunesClientDep = Annotated[ItunesClient, Depends(get_itunes_client)]
