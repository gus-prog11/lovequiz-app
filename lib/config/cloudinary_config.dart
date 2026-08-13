class CloudinaryConfig {
  static const String cloudName = 'w9dqlb91';
  static const String uploadPreset = 'lovequiz_profiles';
  static const String folder = 'profile_photos';

  // Audio upload preset — crear en Cloudinary Dashboard > Settings > Upload
  // como unsigned preset, con "audio/*" en Accepted files.
  static const String audioUploadPreset = 'lovequiz_voice';
  static const String audioFolder = 'voice_memories';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/upload';
}
