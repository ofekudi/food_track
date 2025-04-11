enum AddEntryStatus {
  Added, // Entry was added successfully
  LimitExceeded, // Adding would exceed the daily limit
  Error // An error occurred during addition
}
