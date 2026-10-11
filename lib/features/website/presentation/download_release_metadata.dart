/// Public release metadata supplied to the Flutter Web build.
///
/// The default state is deliberately unavailable. Release values are public
/// metadata; never pass signing credentials through Dart defines.
class DownloadReleaseMetadata {
  const DownloadReleaseMetadata({
    required this.isVerified,
    required this.androidUrl,
    required this.versionName,
    required this.versionCode,
    required this.fileSizeBytes,
    required this.minimumAndroidApi,
    required this.releaseDate,
    required this.sha256,
    required this.signingCertificateSha256,
  });

  static const current = DownloadReleaseMetadata(
    isVerified: bool.fromEnvironment(
      'SAMADHANAI_ANDROID_RELEASE_VERIFIED',
      defaultValue: false,
    ),
    androidUrl: String.fromEnvironment('SAMADHANAI_ANDROID_DOWNLOAD_URL'),
    versionName: String.fromEnvironment('SAMADHANAI_ANDROID_VERSION_NAME'),
    versionCode: String.fromEnvironment('SAMADHANAI_ANDROID_VERSION_CODE'),
    fileSizeBytes: String.fromEnvironment('SAMADHANAI_ANDROID_FILE_SIZE_BYTES'),
    minimumAndroidApi: String.fromEnvironment(
      'SAMADHANAI_ANDROID_MINIMUM_API',
    ),
    releaseDate: String.fromEnvironment('SAMADHANAI_ANDROID_RELEASE_DATE'),
    sha256: String.fromEnvironment('SAMADHANAI_ANDROID_SHA256'),
    signingCertificateSha256: String.fromEnvironment(
      'SAMADHANAI_ANDROID_CERTIFICATE_SHA256',
    ),
  );

  final bool isVerified;
  final String androidUrl;
  final String versionName;
  final String versionCode;
  final String fileSizeBytes;
  final String minimumAndroidApi;
  final String releaseDate;
  final String sha256;
  final String signingCertificateSha256;

  Uri? get downloadUri {
    final uri = Uri.tryParse(androidUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri;
  }

  int? get parsedVersionCode => int.tryParse(versionCode);
  int? get parsedFileSizeBytes => int.tryParse(fileSizeBytes);
  int? get parsedMinimumAndroidApi => int.tryParse(minimumAndroidApi);

  bool get isAndroidAvailable =>
      isVerified &&
      downloadUri != null &&
      versionName.trim().isNotEmpty &&
      RegExp(
        r'^[A-Za-z0-9][A-Za-z0-9._-]{0,30}$',
      ).hasMatch(versionName.trim()) &&
      (parsedVersionCode ?? 0) > 0 &&
      (parsedFileSizeBytes ?? 0) > 0 &&
      (parsedMinimumAndroidApi ?? 0) > 0 &&
      _isSha256(sha256) &&
      _isSha256(signingCertificateSha256);

  String get downloadFileName => 'samadhanai-$versionName+$versionCode.apk';

  static bool _isSha256(String value) =>
      RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(value.trim());
}
