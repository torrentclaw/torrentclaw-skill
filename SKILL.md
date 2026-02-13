---
name: torrentclaw
description: Search and download torrents via TorrentClaw. Use when the user asks to find, search, or download movies, TV shows, or torrents. Detects local torrent clients (Transmission, aria2) and adds magnets directly, or offers magnet link copy and .torrent file download. Supports filtering by type (movie/show), genre, year, quality (480p-2160p), rating, language, and season/episode (S01E05, 1x05). Features API key authentication with tiered rate limits, AI-verified matching, and quality scoring (0-100). Returns titles with posters, ratings, and torrents with magnet links and quality scores.
license: MIT
metadata: {"version": "0.1.13", "repository": "https://github.com/torrentclaw/torrentclaw-skill", "homepage": "https://torrentclaw.com", "openclaw": {"emoji": "🎬", "os": ["darwin", "linux", "win32"]}}
---

# TorrentClaw

Search movies and TV shows across multiple torrent sources with TMDB metadata enrichment. Detect local torrent clients and start downloads automatically.

## Base URL

```
https://torrentclaw.com
```

## Workflow

Follow these steps when the user asks to find or download a torrent:

### Step 1: Detect torrent clients

Run the detection script to check what's available on the user's system:

```bash
bash "$(dirname "$0")/scripts/detect-client.sh"
```

The script outputs JSON with detected clients and OS info. Remember the result for Step 4.

### Step 2: Search for content

Query the TorrentClaw API. Always include the `x-search-source: skill` header for analytics:

```bash
curl -s -H "x-search-source: skill" "https://torrentclaw.com/api/v1/search?q=QUERY&sort=seeders&limit=5"
```

**Useful filters** (append as query params):
- `type=movie` or `type=show`
- `quality=1080p` (also: 720p, 2160p, 480p)
- `genre=Action` (see references/api-reference.md for full list)
- `year_min=2020&year_max=2025`
- `min_rating=7`
- `lang=es` (ISO 639 language code)
- `season=1` — Filter by TV show season
- `episode=5` — Filter by episode number
- `locale=es` — Get titles in Spanish (also: fr, de, pt, it, ja, ko, zh, ru, ar)
- `sort=seeders` (also: relevance, year, rating, added)

### Step 3: Present results

Display results in a clear table format. For each content item show:
- Title, year, content type
- IMDb rating (or TMDB rating as fallback)
- For each torrent: quality, codec, size (human-readable), seeders

Example format:
```
1. Inception (2010) - Movie - IMDb: 8.8
   a) 1080p BluRay x265 - 2.1 GB - 847 seeders
   b) 2160p WEB-DL x265 HDR - 8.3 GB - 234 seeders
   c) 720p BluRay x264 - 1.0 GB - 156 seeders
```

Ask the user which torrent they want.

### Step 4: Handle download

Based on the detection from Step 1:

**If a torrent client was detected:**
Offer to add the magnet link directly:

```bash
bash "$(dirname "$0")/scripts/add-torrent.sh" "MAGNET_URL"
```

Or with a specific client and download directory:

```bash
bash "$(dirname "$0")/scripts/add-torrent.sh" "MAGNET_URL" --client transmission --download-dir ~/Downloads
```

**If NO torrent client was detected:**
Offer these options:
1. **Copy magnet link** — Give the user the full `magnetUrl` from the API response to copy
2. **Download .torrent file** — `curl -o "filename.torrent" "https://torrentclaw.com/api/v1/torrent/INFO_HASH"`
3. **Install a client** — Run the install guide script:

```bash
bash "$(dirname "$0")/scripts/install-guide.sh" transmission
```

Recommend **Transmission** for Linux/macOS (lightweight daemon, simple CLI) and **aria2** as alternative (multi-protocol, no daemon needed).

## Endpoints

### Search — `GET /api/v1/search`

Main search endpoint. Required: `q` (query string).

**Filters:** `type` (movie/show), `genre`, `year_min`, `year_max`, `min_rating` (0-10), `quality` (480p/720p/1080p/2160p), `lang` (ISO 639), `availability` (all/available/unavailable).

**Sorting:** `sort` = relevance | seeders | year | rating | added

**Pagination:** `page` (1-1000), `limit` (1-50, default 20)

**Response:** `{ total, page, pageSize, results: [{ id, imdbId, tmdbId, contentType, title, year, overview, posterUrl, genres, ratingImdb, ratingTmdb, hasTorrents, maxSeeders, torrents: [{ infoHash, magnetUrl, torrentUrl, quality, codec, sourceType, sizeBytes, seeders, leechers, source, qualityScore, scrapedAt, languages, audioCodec, hdrType }] }] }`

**New fields:**
- `hasTorrents` (boolean) — Whether content has any associated torrents
- `maxSeeders` (number) — Highest seeder count across all torrents for this content
- `scrapedAt` (string) — ISO timestamp of last tracker scrape for real-time seeder/leecher counts

### Autocomplete — `GET /api/v1/autocomplete`

Fast typeahead. Param: `q` (min 2 chars). Returns max 8 suggestions.

### Popular — `GET /api/v1/popular`

Trending content by seeders. Params: `limit` (1-24), `page`.

### Recent — `GET /api/v1/recent`

Recently added content. Params: `limit` (1-24), `page`.

### Torrent File — `GET /api/v1/torrent/{infoHash}`

Download .torrent file by 40-char hex info hash. Returns binary `application/x-bittorrent`.

### Stats — `GET /api/v1/stats`

Content/torrent counts and recent ingestion history. No params.

### Content Details — `GET /api/v1/content/:id`

Full metadata for a specific movie or show. Returns complete content object with all torrents, cast, crew, and metadata.

### Track — `GET /api/v1/track`

Analytics tracking endpoint. Params: `contentId` (required), `type` (view/click/download).

### Search Analytics — `GET /api/v1/search-analytics`

Popular searches and trending queries. **Requires API key with pro tier.**

### Cache Stats — `GET /api/v1/cache-stats`

Search cache metrics and performance stats. No params.

### Enrichment Stats — `GET /api/v1/enrichment-stats`

TMDB enrichment progress and coverage statistics. No params.

## Season & Episode Search

TorrentClaw supports smart episode filtering with multiple formats:

**Supported formats:**
- `S01E05` (standard format)
- `1x05` (alternative format)
- `1x05-1x08` (episode ranges)
- `Season 1 Episode 5` (natural language)

**Usage:**

1. **In query text** (automatic parsing):
```bash
curl "https://torrentclaw.com/api/v1/search?q=breaking+bad+S05E14"
```

2. **With explicit parameters**:
```bash
curl "https://torrentclaw.com/api/v1/search?q=breaking+bad&season=5&episode=14"
```

The API automatically detects episode patterns in queries and filters results accordingly.

## API Authentication

TorrentClaw supports optional API key authentication for higher rate limits.

**Rate Limit Tiers:**

| Tier | Requests/min | Requests/day | Authentication |
|------|--------------|--------------|----------------|
| Anonymous | 30 | Unlimited | None |
| Free | 120 | 1,000 | API key required |
| Pro | 1,000 | 10,000 | API key required |
| Internal | Unlimited | Unlimited | API key required |

**Using an API key:**

```bash
# Via header (recommended)
curl -H "Authorization: Bearer tc_live_xxxxx" \
  "https://torrentclaw.com/api/v1/search?q=dune"

# Via query parameter
curl "https://torrentclaw.com/api/v1/search?q=dune&api_key=tc_live_xxxxx"
```

**Rate limit headers in response:**
- `X-RateLimit-Tier` - Your current tier (anonymous/free/pro/internal)
- `X-RateLimit-Remaining` - Requests remaining in current window

**Getting an API key:**
Contact via https://torrentclaw.com/contact or https://torrentclaw.com/api/v1/contact

## MCP Server Integration

For users of **Claude Desktop**, **Cursor**, or **Windsurf**, TorrentClaw is also available as an MCP (Model Context Protocol) server:

```bash
npx @torrentclaw/mcp
```

**MCP vs Skill:**
- **Skill (this file)**: For OpenClaw, Claude Code, Cline, Roo Code — natural language interface
- **MCP Server**: For Claude Desktop, Cursor, Windsurf — structured tools interface
- **Both** use the same TorrentClaw API backend

See https://torrentclaw.com/mcp for MCP installation and usage.

## Common Patterns

**Find best quality torrent for a movie:**
Search with `sort=seeders`, pick the torrent with highest `qualityScore`.

**Find 4K content:**
Use `quality=2160p` filter.

**Browse Spanish-language torrents:**
Use `lang=es` filter.

**Search for a specific TV episode:**
```bash
curl "https://torrentclaw.com/api/v1/search?q=entrevias+S01E05&locale=es"
```

**Search with API key for higher rate limits:**
```bash
curl -H "Authorization: Bearer tc_live_xxxxx" \
  "https://torrentclaw.com/api/v1/search?q=dune&quality=2160p"
```

**Find popular sci-fi movies:**
```bash
curl "https://torrentclaw.com/api/v1/search?genre=science-fiction&type=movie&sort=seeders"
```

**Track content view for analytics:**
```bash
curl "https://torrentclaw.com/api/v1/track?contentId=123&type=view"
```

## Troubleshooting

**Scripts not executable:** Run `chmod +x scripts/*.sh` in the skill directory.

**Transmission not detected but installed:** Ensure `transmission-remote` is in PATH. On some systems the package is `transmission-cli`.

**aria2 starts but exits immediately:** aria2c in direct mode downloads to current directory. Use `--download-dir` flag or `--daemon` mode.

**No torrent client detected:** Run `bash scripts/install-guide.sh transmission` to see installation instructions for your OS (Linux, macOS, Windows/WSL).

**API key not working:**
- Verify the key format: `tc_live_` followed by 32 hex characters
- Check the `Authorization: Bearer <key>` header is correct
- Ensure the key hasn't expired (contact support if needed)
- Check `X-RateLimit-Tier` header in responses to confirm tier

**Rate limits:**
- Anonymous: 30 req/min (no auth)
- Free tier: 120 req/min, 1K/day (with API key)
- Pro tier: 1K req/min, 10K/day (with API key)
- If you get 429, wait a moment or use an API key for higher limits

**Windows users:** Scripts require bash. Use WSL (Windows Subsystem for Linux) or Git Bash.

## Links

- **Website**: https://torrentclaw.com
- **GitHub**: https://github.com/torrentclaw/torrentclaw-skill
- **OpenAPI Spec**: https://torrentclaw.com/api/openapi.json
- **Swagger UI**: https://torrentclaw.com/api/docs
- **MCP Server**: https://torrentclaw.com/mcp
- **llms.txt**: https://torrentclaw.com/llms.txt
