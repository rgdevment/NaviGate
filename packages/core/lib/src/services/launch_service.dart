abstract interface class LaunchService {
  Future<void> launch(
    String executablePath,
    String url,
    List<String> extraArgs,
  );
}
