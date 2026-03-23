String resolveImageUrl(String? imagePath, {required String fallbackUrl}) {
  final normalized = imagePath?.trim();
  if (normalized != null &&
      normalized.isNotEmpty &&
      (normalized.startsWith('http://') || normalized.startsWith('https://'))) {
    return normalized;
  }
  return fallbackUrl;
}

String resolvePlantImageUrl(String? imagePath) {
  return resolveImageUrl(
    imagePath,
    fallbackUrl:
        'https://images.unsplash.com/photo-1485909645661-8e05c8680d28?q=80&w=600&auto=format&fit=crop',
  );
}

String resolveAvatarImageUrl(String? imagePath) {
  return resolveImageUrl(
    imagePath,
    fallbackUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=400&auto=format&fit=crop',
  );
}

String resolvePostImageUrl(String? imagePath) {
  return resolveImageUrl(
    imagePath,
    fallbackUrl:
        'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?q=80&w=900&auto=format&fit=crop',
  );
}
