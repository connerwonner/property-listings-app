
import type { Sponsor } from './types';

interface SponsorBannerProps {
  sponsor: Sponsor;
}

export default function SponsorBanner({ sponsor }: SponsorBannerProps) {
  return (
    <aside
      aria-label={`Sponsored by ${sponsor.name}`}
      className="w-full max-w-4xl mx-auto my-8 p-6 bg-gray-50 border border-gray-200 rounded-lg flex flex-col sm:flex-row items-center justify-between shadow-sm"
    >
      <div className="mb-4 sm:mb-0">
        <p className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">Proud Sponsor</p>
        <img
          src={sponsor.imageUrl}
          alt={sponsor.altText}
          className="h-12 w-auto object-contain"
        />
      </div>

      <a
        href={sponsor.websiteUrl}
  target="_blank"
  rel="noopener noreferrer"
  className="..."
>
  Visit {sponsor.name}
  <span className="sr-only"> (opens in a new tab)</span>
</a>
    </aside>
  );
}