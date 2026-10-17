/// UI microcopy, branding strings, and demo constants from DESIGN.md
class AppStrings {
  static const String appName = 'EzyHelpers Partner';
  static const String appTagline = 'Manage your jobs on the go';
  static const String appVersion = 'Demo build v1.0';

  // Login
  static const String loginTitle = 'Sign in';
  static const String usernameLabel = 'Username';
  static const String passwordLabel = 'Password';
  static const String usernameRequired = 'Username is required';
  static const String passwordRequired = 'Password is required';
  static const String demoCredentialsHint = 'Demo build: use helper1 / Demo@1234';
  static const String incorrectCredentials = 'Incorrect username or password';

  // Jobs List
  static const String jobsListTitle = 'My Jobs';
  static const String emptyListTitle = 'No jobs assigned yet';
  static const String emptyListHint = 'New jobs will show up here';
  static const String listLoadFailed = "Couldn't load your jobs. Tap Retry.";

  // Job Details
  static const String jobNotFound = 'Job not found';
  static const String invalidTransition = "This job can't move to that status. Refresh and try again.";
  static const String startJobButton = 'Start job';
  static const String markCompletedButton = 'Mark as completed';
  static const String completedLabel = 'Completed';
  static const String confirmDialogCancel = 'Cancel';
  static const String confirmDialogConfirm = 'Confirm';

  // System & Errors
  static const String networkError = "Can't reach the server. Check your connection and try again.";
  static const String sessionExpired = 'Session expired. Please sign in again.';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';
  static const String logout = 'Logout';
  static const String logoutConfirmTitle = 'Logout';
  static const String logoutConfirmMessage = 'Are you sure you want to log out?';
}
