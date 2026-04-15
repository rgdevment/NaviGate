abstract interface class StartupService {
  Future<void> enable(String executablePath);

  Future<void> disable();

  Future<bool> get isEnabled;
}
