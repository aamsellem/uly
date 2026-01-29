"""Content fetcher for various platforms.

Extracts content from URLs: YouTube, Reddit, Twitter, web pages.
"""

import re
import json
from dataclasses import dataclass
from typing import Optional
from urllib.parse import urlparse, parse_qs

import requests
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._errors import TranscriptsDisabled, NoTranscriptFound


@dataclass
class FetchedContent:
    """Represents fetched content from a URL."""
    url: str
    platform: str  # youtube, reddit, twitter, web
    title: Optional[str] = None
    content: Optional[str] = None
    transcript: Optional[str] = None
    author: Optional[str] = None
    metadata: Optional[dict] = None
    error: Optional[str] = None


class ContentFetcher:
    """Fetches and extracts content from various platforms."""

    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        })

    def detect_platform(self, url: str) -> str:
        """Detect which platform a URL belongs to."""
        parsed = urlparse(url)
        domain = parsed.netloc.lower()

        if "youtube.com" in domain or "youtu.be" in domain:
            return "youtube"
        elif "reddit.com" in domain or "redd.it" in domain:
            return "reddit"
        elif "twitter.com" in domain or "x.com" in domain:
            return "twitter"
        elif "instagram.com" in domain:
            return "instagram"
        elif "linkedin.com" in domain:
            return "linkedin"
        else:
            return "web"

    def fetch(self, url: str) -> FetchedContent:
        """Fetch content from any supported URL."""
        platform = self.detect_platform(url)

        fetchers = {
            "youtube": self._fetch_youtube,
            "reddit": self._fetch_reddit,
            "twitter": self._fetch_twitter,
            "instagram": self._fetch_instagram,
            "linkedin": self._fetch_linkedin,
            "web": self._fetch_web,
        }

        fetcher = fetchers.get(platform, self._fetch_web)
        return fetcher(url, platform)

    def _extract_youtube_id(self, url: str) -> Optional[str]:
        """Extract video ID from YouTube URL."""
        parsed = urlparse(url)

        if "youtu.be" in parsed.netloc:
            return parsed.path.lstrip("/")

        if "youtube.com" in parsed.netloc:
            if parsed.path == "/watch":
                return parse_qs(parsed.query).get("v", [None])[0]
            elif "/shorts/" in parsed.path:
                return parsed.path.split("/shorts/")[1].split("/")[0]
            elif "/live/" in parsed.path:
                return parsed.path.split("/live/")[1].split("/")[0]

        return None

    def _fetch_youtube(self, url: str, platform: str) -> FetchedContent:
        """Fetch YouTube video transcript and metadata."""
        video_id = self._extract_youtube_id(url)

        if not video_id:
            return FetchedContent(
                url=url,
                platform=platform,
                error="Could not extract YouTube video ID"
            )

        result = FetchedContent(url=url, platform=platform, metadata={"video_id": video_id})

        # Try to get video title via oEmbed (no API key needed)
        try:
            oembed_url = f"https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={video_id}&format=json"
            resp = self.session.get(oembed_url, timeout=10)
            if resp.ok:
                data = resp.json()
                result.title = data.get("title")
                result.author = data.get("author_name")
        except Exception:
            pass

        # Try to get transcript
        try:
            api = YouTubeTranscriptApi()
            transcript_result = api.fetch(video_id)
            # Format transcript with timestamps
            lines = []
            for snippet in transcript_result:
                start = int(snippet.start)
                mins, secs = divmod(start, 60)
                hours, mins = divmod(mins, 60)
                if hours:
                    timestamp = f"[{hours}:{mins:02d}:{secs:02d}]"
                else:
                    timestamp = f"[{mins}:{secs:02d}]"
                lines.append(f"{timestamp} {snippet.text}")

            result.transcript = "\n".join(lines)
            result.content = f"YouTube video with {len(transcript_result)} transcript segments"

        except TranscriptsDisabled:
            result.error = "Transcripts are disabled for this video"
        except NoTranscriptFound:
            result.error = "No transcript available for this video"
        except Exception as e:
            result.error = f"Could not fetch transcript: {str(e)}"

        return result

    def _fetch_reddit(self, url: str, platform: str) -> FetchedContent:
        """Fetch Reddit post content."""
        result = FetchedContent(url=url, platform=platform)

        try:
            # Reddit JSON API - append .json to URL
            json_url = url.rstrip("/") + ".json"
            resp = self.session.get(json_url, timeout=10)

            if not resp.ok:
                result.error = f"Reddit returned status {resp.status_code}"
                return result

            data = resp.json()

            # Post data is in first element
            if data and len(data) > 0:
                post = data[0]["data"]["children"][0]["data"]
                result.title = post.get("title")
                result.author = post.get("author")
                result.content = post.get("selftext") or post.get("url")
                result.metadata = {
                    "subreddit": post.get("subreddit"),
                    "score": post.get("score"),
                    "num_comments": post.get("num_comments"),
                    "created_utc": post.get("created_utc"),
                }

                # Get top comments if available
                if len(data) > 1:
                    comments = data[1]["data"]["children"]
                    top_comments = []
                    for c in comments[:5]:  # Top 5 comments
                        if c["kind"] == "t1":
                            comment_data = c["data"]
                            top_comments.append({
                                "author": comment_data.get("author"),
                                "body": comment_data.get("body", "")[:500],
                                "score": comment_data.get("score"),
                            })
                    if top_comments:
                        result.metadata["top_comments"] = top_comments

        except Exception as e:
            result.error = f"Could not fetch Reddit post: {str(e)}"

        return result

    def _fetch_twitter(self, url: str, platform: str) -> FetchedContent:
        """Fetch Twitter/X content (limited without API)."""
        result = FetchedContent(url=url, platform=platform)
        result.content = "Twitter/X content (requires API or manual viewing)"
        result.error = "Twitter content requires API access"
        return result

    def _fetch_instagram(self, url: str, platform: str) -> FetchedContent:
        """Fetch Instagram content (limited without API)."""
        result = FetchedContent(url=url, platform=platform)

        try:
            # Try to get oEmbed data
            oembed_url = f"https://api.instagram.com/oembed?url={url}"
            resp = self.session.get(oembed_url, timeout=10)

            if resp.ok:
                data = resp.json()
                result.title = data.get("title")
                result.author = data.get("author_name")
                result.content = data.get("title") or "Instagram content"
                result.metadata = {
                    "author_url": data.get("author_url"),
                    "thumbnail_url": data.get("thumbnail_url"),
                }
            else:
                result.content = "Instagram content (requires login to view)"
                result.error = "Instagram content is restricted"

        except Exception as e:
            result.error = f"Could not fetch Instagram content: {str(e)}"
            result.content = "Instagram content (could not fetch)"

        return result

    def _fetch_linkedin(self, url: str, platform: str) -> FetchedContent:
        """Fetch LinkedIn content (limited without API)."""
        result = FetchedContent(url=url, platform=platform)
        result.content = "LinkedIn content (requires login to view full content)"
        result.error = "LinkedIn content is restricted without authentication"
        return result

    def _fetch_web(self, url: str, platform: str) -> FetchedContent:
        """Fetch generic web page content."""
        result = FetchedContent(url=url, platform=platform)

        try:
            resp = self.session.get(url, timeout=15)

            if not resp.ok:
                result.error = f"HTTP {resp.status_code}"
                return result

            # Basic extraction - title from <title> tag
            html = resp.text
            title_match = re.search(r"<title[^>]*>([^<]+)</title>", html, re.IGNORECASE)
            if title_match:
                result.title = title_match.group(1).strip()

            # Try to extract main content (very basic)
            # Remove script and style tags
            content = re.sub(r"<script[^>]*>.*?</script>", "", html, flags=re.DOTALL | re.IGNORECASE)
            content = re.sub(r"<style[^>]*>.*?</style>", "", content, flags=re.DOTALL | re.IGNORECASE)
            # Remove HTML tags
            content = re.sub(r"<[^>]+>", " ", content)
            # Clean up whitespace
            content = re.sub(r"\s+", " ", content).strip()

            # Truncate to reasonable length
            result.content = content[:5000] if len(content) > 5000 else content

        except Exception as e:
            result.error = f"Could not fetch page: {str(e)}"

        return result

    def extract_links(self, text: str) -> list[str]:
        """Extract all URLs from text."""
        url_pattern = r'https?://[^\s<>"{}|\\^`\[\]]+'
        return re.findall(url_pattern, text)


def main():
    """CLI for testing content fetcher."""
    import argparse

    parser = argparse.ArgumentParser(description="Fetch content from URLs")
    parser.add_argument("url", help="URL to fetch")
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    fetcher = ContentFetcher()
    result = fetcher.fetch(args.url)

    if args.json:
        output = {
            "url": result.url,
            "platform": result.platform,
            "title": result.title,
            "author": result.author,
            "content": result.content[:500] if result.content else None,
            "has_transcript": bool(result.transcript),
            "transcript_length": len(result.transcript) if result.transcript else 0,
            "error": result.error,
            "metadata": result.metadata,
        }
        print(json.dumps(output, indent=2))
    else:
        print(f"Platform: {result.platform}")
        print(f"Title: {result.title or 'N/A'}")
        print(f"Author: {result.author or 'N/A'}")
        if result.error:
            print(f"Error: {result.error}")
        if result.content:
            print(f"\nContent preview:\n{result.content[:500]}...")
        if result.transcript:
            print(f"\nTranscript ({len(result.transcript)} chars):")
            print(result.transcript[:1000] + "..." if len(result.transcript) > 1000 else result.transcript)


if __name__ == "__main__":
    main()
