# List all Windows optional features and format the output in a table
# The 'more' command ensures the output is displayed page by page, useful for long lists
get-windowsoptionalfeature -online | ft | more
