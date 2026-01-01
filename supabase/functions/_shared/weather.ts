// Open-Meteo Weather API wrapper
// Free weather API - no API key required

export interface WeatherData {
  temperature_f: number;
  temperature_c: number;
  condition: string;
  condition_code: number;
  humidity: number;
  wind_speed_mph: number;
  feels_like_f: number;
  is_day: boolean;
  location?: {
    city?: string;
    country?: string;
  };
}

export interface WeatherError {
  error: string;
}

// Weather condition codes to human-readable descriptions
const WEATHER_CONDITIONS: Record<number, string> = {
  0: 'Clear',
  1: 'Mainly Clear',
  2: 'Partly Cloudy',
  3: 'Overcast',
  45: 'Foggy',
  48: 'Depositing Rime Fog',
  51: 'Light Drizzle',
  53: 'Moderate Drizzle',
  55: 'Dense Drizzle',
  56: 'Light Freezing Drizzle',
  57: 'Dense Freezing Drizzle',
  61: 'Slight Rain',
  63: 'Moderate Rain',
  65: 'Heavy Rain',
  66: 'Light Freezing Rain',
  67: 'Heavy Freezing Rain',
  71: 'Slight Snow',
  73: 'Moderate Snow',
  75: 'Heavy Snow',
  77: 'Snow Grains',
  80: 'Slight Rain Showers',
  81: 'Moderate Rain Showers',
  82: 'Violent Rain Showers',
  85: 'Slight Snow Showers',
  86: 'Heavy Snow Showers',
  95: 'Thunderstorm',
  96: 'Thunderstorm with Slight Hail',
  99: 'Thunderstorm with Heavy Hail',
};

// Convert Celsius to Fahrenheit
function celsiusToFahrenheit(celsius: number): number {
  return Math.round((celsius * 9) / 5 + 32);
}

// Convert km/h to mph
function kmhToMph(kmh: number): number {
  return Math.round(kmh * 0.621371);
}

// Fetch current weather from Open-Meteo
export async function getWeather(
  latitude: number,
  longitude: number
): Promise<WeatherData | WeatherError> {
  try {
    // Validate coordinates
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return { error: 'Invalid coordinates' };
    }

    const url = new URL('https://api.open-meteo.com/v1/forecast');
    url.searchParams.set('latitude', latitude.toString());
    url.searchParams.set('longitude', longitude.toString());
    url.searchParams.set('current', 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day');
    url.searchParams.set('temperature_unit', 'celsius');
    url.searchParams.set('wind_speed_unit', 'kmh');
    url.searchParams.set('timezone', 'auto');

    const response = await fetch(url.toString());

    if (!response.ok) {
      return { error: `Weather API error: ${response.status}` };
    }

    const data = await response.json();
    const current = data.current;

    if (!current) {
      return { error: 'No weather data available' };
    }

    const temperatureC = current.temperature_2m;
    const temperatureF = celsiusToFahrenheit(temperatureC);
    const feelsLikeC = current.apparent_temperature;
    const feelsLikeF = celsiusToFahrenheit(feelsLikeC);
    const conditionCode = current.weather_code;

    return {
      temperature_f: temperatureF,
      temperature_c: Math.round(temperatureC),
      condition: WEATHER_CONDITIONS[conditionCode] || 'Unknown',
      condition_code: conditionCode,
      humidity: current.relative_humidity_2m,
      wind_speed_mph: kmhToMph(current.wind_speed_10m),
      feels_like_f: feelsLikeF,
      is_day: current.is_day === 1,
    };
  } catch (error) {
    return {
      error: error instanceof Error ? error.message : 'Failed to fetch weather data',
    };
  }
}

// Reverse geocode coordinates to get city/country
export async function reverseGeocode(
  latitude: number,
  longitude: number
): Promise<{ city?: string; country?: string } | null> {
  try {
    // Using Open-Meteo's geocoding API for reverse lookup
    const url = new URL('https://nominatim.openstreetmap.org/reverse');
    url.searchParams.set('lat', latitude.toString());
    url.searchParams.set('lon', longitude.toString());
    url.searchParams.set('format', 'json');

    const response = await fetch(url.toString(), {
      headers: {
        'User-Agent': 'FragranceStack/1.0',
      },
    });

    if (!response.ok) {
      return null;
    }

    const data = await response.json();

    return {
      city: data.address?.city || data.address?.town || data.address?.village,
      country: data.address?.country,
    };
  } catch {
    return null;
  }
}

// Get weather with location info
export async function getWeatherWithLocation(
  latitude: number,
  longitude: number
): Promise<WeatherData | WeatherError> {
  const weather = await getWeather(latitude, longitude);

  if ('error' in weather) {
    return weather;
  }

  // Try to get location info (don't fail if it doesn't work)
  const location = await reverseGeocode(latitude, longitude);
  if (location) {
    weather.location = location;
  }

  return weather;
}

// Check if weather response is an error
export function isWeatherError(
  response: WeatherData | WeatherError
): response is WeatherError {
  return 'error' in response;
}

// Get season recommendation based on temperature
export function getSeasonFromTemperature(temperatureF: number): string {
  if (temperatureF >= 80) return 'summer';
  if (temperatureF >= 65) return 'spring';
  if (temperatureF >= 45) return 'fall';
  return 'winter';
}

// Format weather for LLM context
export function formatWeatherForPrompt(weather: WeatherData): string {
  const parts = [
    `Temperature: ${weather.temperature_f}°F (feels like ${weather.feels_like_f}°F)`,
    `Conditions: ${weather.condition}`,
    `Humidity: ${weather.humidity}%`,
  ];

  if (weather.location?.city) {
    parts.unshift(`Location: ${weather.location.city}${weather.location.country ? `, ${weather.location.country}` : ''}`);
  }

  return parts.join('\n');
}
