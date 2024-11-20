# List all Windows optional features that are currently disabled and display them in a table with pagination
get-windowsoptionalfeature -online | where state -like disabled* | ft | more
