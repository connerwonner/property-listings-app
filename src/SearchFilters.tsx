

interface SearchFiltersProps {
  onSearch: (searchTerm: string) => void;
  onFilterChange: (filter: string) => void;
}

export default function SearchFilters({ onSearch, onFilterChange }: SearchFiltersProps) {
  return (
    <section aria-labelledby="filter-heading" className="w-full bg-white p-6 border border-gray-200 rounded-lg shadow-sm mb-8">
      <h2 id="filter-heading" className="text-2xl font-bold text-gray-900 mb-6">Find Your Home</h2>

      <form
        onSubmit={(e) => e.preventDefault()}
        className="flex flex-col md:flex-row gap-4"
      >
        <div className="flex-1 flex flex-col gap-2">
          <label htmlFor="search-input" className="text-sm font-semibold text-gray-700">Location or ZIP</label>
          <input
            type="text"
            id="search-input"
            placeholder="e.g. 90272"
            onChange={(e) => onSearch(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>

        <div className="flex-1 flex flex-col gap-2">
          <label htmlFor="property-type-select" className="text-sm font-semibold text-gray-700">Property Type</label>
          <select
            id="property-type-select"
            onChange={(e) => onFilterChange(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white"
          >
            <option value="all">All Properties</option>
            <option value="single-family">Single Family</option>
            <option value="condo">Condominium</option>
          </select>
        </div>

        <div className="flex items-end">
          <button
            type="submit"
            className="w-full md:w-auto px-8 py-2 bg-blue-600 text-white font-bold rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
          >
            Search
          </button>
        </div>
      </form>
    </section>
  );
}