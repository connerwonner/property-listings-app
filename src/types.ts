export interface Property {
  id: string;
  address: string;
  price: number;
  bedrooms: number;
  bathrooms: number;
  sqft: number;
  propertyType: string;
  imageUrl: string;
}

export interface Sponsor {
  id: string;
  name: string;
  imageUrl: string;
  websiteUrl: string;
  altText: string;
}