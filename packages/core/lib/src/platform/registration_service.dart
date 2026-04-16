abstract interface class RegistrationService {
  Future<void> register(String executablePath);

  Future<void> unregister();

  Future<bool> get isDefault;

  Future<Set<String>> get defaultAssociations;
}
