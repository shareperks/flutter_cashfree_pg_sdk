String imageUrl(String url) {
  if (url.startsWith('http')) {
    return url;
  }
  return 'https://backend-api.shareperks.in/api/file/get/?key=$url';
  // return 'https://localhost.sourav.email/api/file/get/?key=$url';
}
