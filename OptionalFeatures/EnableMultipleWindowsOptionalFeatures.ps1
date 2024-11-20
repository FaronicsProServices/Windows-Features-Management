# Define the list of features to enable
$features = @(
    "TelnetClient",
    "TFTP",
    "NetFx3"
)

# Enable all features
Enable-WindowsOptionalFeature -Online -FeatureName $features -All -NoRestart
