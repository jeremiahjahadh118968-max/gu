# gu

A static site for stayat.hotelconsuladoinn.com.

## Local preview
Run the local server:

```bash
python3 -m http.server 8000
```

Then open http://127.0.0.1:8000/.

## Production deployment
This repository includes static hosting assets for domain-based hosting:
- `CNAME` for the custom domain
- `.nojekyll` to bypass Jekyll processing

For a real production deployment:
1. Publish the site to a static host (GitHub Pages, Netlify, Vercel, or your own web server).
2. Point `stayat.hotelconsuladoinn.com` DNS to the host.
3. Confirm the site responds on the custom domain.

## Current local status
- Homepage: index.html
- Local server: running on port 8000
- VPN setup: configured in setup_wireguard_auto.sh and wg0.conf