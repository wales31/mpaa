enum Flavor { dev, stage, prod }

extension FlavorX on Flavor {
  String get name {
    switch (this) {
      case Flavor.dev:
        return 'dev';
      case Flavor.stage:
        return 'stage';
      case Flavor.prod:
        return 'prod';
    }
  }

  static Flavor fromString(String value) {
    switch (value.toLowerCase()) {
      case 'dev':
        return Flavor.dev;
      case 'stage':
        return Flavor.stage;
      case 'prod':
        return Flavor.prod;
      default:
        return Flavor.dev;
    }
  }
}
