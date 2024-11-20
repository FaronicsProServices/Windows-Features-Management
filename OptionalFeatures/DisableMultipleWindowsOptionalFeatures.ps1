# Define the list of features to disable
$featuresToDisable = @(
    " TelnetClient ",
    " TFTP ",
    "WindowsMediaPlayer "
)

# Disable all features
Disable-WindowsOptionalFeature -Online -FeatureName $featuresToDisable -NoRestart
