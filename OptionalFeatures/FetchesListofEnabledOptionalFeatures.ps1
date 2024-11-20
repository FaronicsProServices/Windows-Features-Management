# List all Windows optional features that are currently enabled
get-windowsoptionalfeature -online | where state -like enabled* | ft | more
