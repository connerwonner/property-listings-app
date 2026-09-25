
import type { Property } from './types';

interface PropertyCardProps {
  property: Property;
}

export default function PropertyCard({ property }: PropertyCardProps) {
  return (
    <article className="w-full md:w-1/2 lg:w-1/3 p-4 border border-gray-200 rounded-lg shadow-sm transition-shadow hover:shadow-md focus-within:ring-2 focus-within:ring-blue-500">
      <img
        src={property.imageUrl}
        alt={`Exterior view of the ${property.propertyType} located at ${property.address}`}
        className="w-full h-48 object-cover rounded-t-md"
      />
      <div className="p-4">
        <h3 className="text-xl font-bold text-gray-900">
          ${property.price.toLocaleString()}
        </h3>
        <p className="text-gray-600 mt-1">{property.address}</p>

        <div className="flex justify-between mt-3 text-sm text-gray-700">
          <span>{property.bedrooms} Beds</span>
          <span>{property.bathrooms} Baths</span>
          <span>{property.sqft.toLocaleString()} sqft</span>
        </div>

        <div className="mt-5 flex gap-3">
          <button
            className="flex-1 px-4 py-2 bg-blue-600 text-white font-semibold rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            aria-label={`Save ${property.address} to favorites`}
          >
            Save
          </button>
          <a
            href={`/properties/${property.id}`}
            className="flex-1 text-center px-4 py-2 border border-blue-600 text-blue-600 font-semibold rounded-md hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            aria-label={`View full details for ${property.address}`}
          >
            Details
          </a>
        </div>
      </div>
    </article>
  );
}