import PropertyCard from './PropertyCard';
import SponsorBanner from './SponsorBanner';
import SearchFilters from './SearchFilters';
import { sampleProperties, sampleSponsor } from './data';

export default function App() {
  return (
    <main className="max-w-6xl mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">Find Your Next Home</h1>

      <SponsorBanner sponsor={sampleSponsor} />

      <SearchFilters
        onSearch={(term) => console.log('search:', term)}
        onFilterChange={(filter) => console.log('filter:', filter)}
      />

      {/* flex-wrap, not grid-cols — PropertyCard already sets its own
          w-full / md:w-1/2 / lg:w-1/3, so the parent just needs to wrap */}
      <div aria-label="Property listings" className="flex flex-wrap -m-2">
        {sampleProperties.map((property) => (
          <PropertyCard key={property.id} property={property} />
        ))}
      </div>
    </main>
  );
}