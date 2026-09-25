import type { Property, Sponsor } from './types';

export const sampleProperties: Property[] = [
  {
    id: 'p1',
    address: '123 Maple St, Springfield',
    price: 425000,
    bedrooms: 3,
    bathrooms: 2,
    sqft: 1600,
    propertyType: 'house',
    imageUrl: '/images/house1.jpg',
  },
  {
    id: 'p2',
    address: '45 Ocean Ave, Bay City',
    price: 610000,
    bedrooms: 4,
    bathrooms: 3,
    sqft: 2100,
    propertyType: 'house',
    imageUrl: '/images/house2.jpg',
  },
  {
    id: 'p3',
    address: '78 Elm Court, Rivertown',
    price: 289000,
    bedrooms: 2,
    bathrooms: 1,
    sqft: 1050,
    propertyType: 'condo',
    imageUrl: '/images/house3.jpg',
  },
];

export const sampleSponsor: Sponsor = {
  id: 's1',
  name: 'Springfield Home Inspections',
  imageUrl: '/images/sponsor-logo.png',
  websiteUrl: 'https://example.com/springfield-inspections',
  altText: 'Springfield Home Inspections logo',
};