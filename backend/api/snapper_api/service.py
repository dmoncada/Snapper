import logging

from .discogs import DiscogsClient
from .itunes import ItunesClient
from .models import TracklistRequest, TracklistResponse
from .upstream import UpstreamError

logger = logging.getLogger(__name__)


class MetadataService:
    def __init__(self, discogs: DiscogsClient, itunes: ItunesClient):
        self.discogs = discogs
        self.itunes = itunes

    async def resolve_tracks(self, request: TracklistRequest) -> TracklistResponse:
        try:
            resolved = await self.itunes.resolve_tracks(
                request.artist.strip(), request.title.strip()
            )
            if resolved is not None:
                return resolved
        except UpstreamError:
            logger.info(
                "iTunes failed; falling back to Discogs release %s",
                request.discogsReleaseId,
            )

        tracks = await self.discogs.tracks(request.discogsReleaseId)
        return TracklistResponse(source="discogs", itunesUrl=None, tracks=tracks)
