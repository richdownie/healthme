import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'dev.fly.healthme',
  appName: 'HealthMe',
  webDir: 'www',
  server: {
    url: 'https://healthme.fly.dev',
    allowNavigation: ['healthme.fly.dev']
  },
  ios: {
    contentInset: 'always',
    scrollEnabled: true
  }
};

export default config;
