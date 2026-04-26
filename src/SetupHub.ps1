param(
    [Parameter(Mandatory)]
    [string]$CatalogPath
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$catalog = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $CatalogPath), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$apps = New-Object System.Collections.ObjectModel.ObservableCollection[object]

foreach ($app in @($catalog.apps | Sort-Object category, name)) {
    $apps.Add([pscustomobject]@{
        Selected = $false
        Id = $app.id
        Name = $app.name
        Category = $app.category
        Type = $app.install.type
        Status = $app.status
        InstallState = "Unchecked"
        Source = if (-not [string]::IsNullOrWhiteSpace($app.install.packageId)) { $app.install.packageId } elseif (-not [string]::IsNullOrWhiteSpace($app.install.url)) { $app.install.url } else { $app.install.installer }
        Description = $app.description
        Raw = $app
    })
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Personal Windows Setup Hub" Height="760" Width="1120"
        WindowStartupLocation="CenterScreen" Background="#F5F7FA"
        FontFamily="Microsoft YaHei UI, Segoe UI">
  <Grid Margin="16">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="2*"/>
      <ColumnDefinition Width="360"/>
    </Grid.ColumnDefinitions>

    <StackPanel Grid.Row="0" Grid.ColumnSpan="2" Margin="0,0,0,12">
      <TextBlock Text="Personal Windows Setup Hub" FontSize="24" FontWeight="SemiBold" Foreground="#17202A"/>
      <TextBlock Name="SummaryText" FontSize="13" Foreground="#5D6D7E" Margin="0,4,0,0"/>
    </StackPanel>

    <Border Grid.Row="1" Grid.Column="0" Background="White" BorderBrush="#D8DEE9" BorderThickness="1" CornerRadius="6" Padding="10">
      <DockPanel>
        <WrapPanel DockPanel.Dock="Top" Margin="0,0,0,10">
          <TextBox Name="SearchBox" Width="260" Height="30" VerticalContentAlignment="Center" Margin="0,0,8,0"/>
          <ComboBox Name="CategoryBox" Width="180" Height="30" Margin="0,0,8,0"/>
          <ComboBox Name="InstallStateBox" Width="130" Height="30" Margin="0,0,8,0"/>
          <Button Name="CheckInstalledButton" Content="Check installed" Height="30" Padding="12,0" Margin="0,0,8,0"/>
          <Button Name="SelectReadyButton" Content="Select ready winget apps" Height="30" Padding="12,0" Margin="0,0,8,0"/>
          <Button Name="ClearButton" Content="Clear" Height="30" Padding="12,0"/>
        </WrapPanel>

        <ListView Name="AppList" SelectionMode="Single">
          <ListView.View>
            <GridView>
              <GridViewColumn Width="38">
                <GridViewColumn.CellTemplate>
                  <DataTemplate>
                    <CheckBox IsChecked="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/>
                  </DataTemplate>
                </GridViewColumn.CellTemplate>
              </GridViewColumn>
              <GridViewColumn Header="Name" DisplayMemberBinding="{Binding Name}" Width="230"/>
              <GridViewColumn Header="Category" DisplayMemberBinding="{Binding Category}" Width="120"/>
              <GridViewColumn Header="Install" DisplayMemberBinding="{Binding Type}" Width="90"/>
              <GridViewColumn Header="Installed" DisplayMemberBinding="{Binding InstallState}" Width="100"/>
              <GridViewColumn Header="Status" DisplayMemberBinding="{Binding Status}" Width="90"/>
              <GridViewColumn Header="Package / Source" DisplayMemberBinding="{Binding Source}" Width="220"/>
            </GridView>
          </ListView.View>
        </ListView>
      </DockPanel>
    </Border>

    <Border Grid.Row="1" Grid.Column="1" Background="White" BorderBrush="#D8DEE9" BorderThickness="1" CornerRadius="6" Padding="14" Margin="12,0,0,0">
      <StackPanel>
        <TextBlock Name="DetailName" Text="Select an app" FontSize="19" FontWeight="SemiBold" Foreground="#17202A" TextWrapping="Wrap"/>
        <TextBlock Name="DetailMeta" FontSize="13" Foreground="#5D6D7E" Margin="0,8,0,0" TextWrapping="Wrap"/>
        <Separator Margin="0,12,0,12"/>
        <TextBlock Name="DetailDescription" FontSize="14" Foreground="#273746" TextWrapping="Wrap"/>
        <Button Name="OpenOfficialButton" Content="Open official site" Height="30" Padding="10,0" HorizontalAlignment="Left" Margin="0,14,0,0"/>
        <DockPanel Margin="0,18,0,6">
          <TextBlock Text="Config paths" FontSize="14" FontWeight="SemiBold" Foreground="#17202A" VerticalAlignment="Center"/>
          <Button Name="OpenConfigButton" Content="Open config path" Height="28" Padding="10,0" HorizontalAlignment="Right" DockPanel.Dock="Right"/>
        </DockPanel>
        <TextBox Name="ConfigPaths" MinHeight="90" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderBrush="#D8DEE9"/>
        <Separator Margin="0,14,0,12"/>
        <TextBlock Text="Install queue" FontSize="14" FontWeight="SemiBold" Foreground="#17202A"/>
        <ProgressBar Name="InstallProgress" Height="12" Minimum="0" Maximum="100" Margin="0,8,0,8"/>
        <ListView Name="QueueList" MinHeight="90" MaxHeight="130" BorderBrush="#D8DEE9">
          <ListView.View>
            <GridView>
              <GridViewColumn Header="App" DisplayMemberBinding="{Binding Name}" Width="190"/>
              <GridViewColumn Header="Status" DisplayMemberBinding="{Binding Status}" Width="110"/>
            </GridView>
          </ListView.View>
        </ListView>
        <TextBox Name="InstallLogBox" MinHeight="120" Margin="0,8,0,0" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderBrush="#D8DEE9" FontFamily="Consolas"/>
      </StackPanel>
    </Border>

    <Border Grid.Row="2" Grid.ColumnSpan="2" Background="White" BorderBrush="#D8DEE9" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,12,0,0">
      <DockPanel>
        <TextBlock Name="StatusText" VerticalAlignment="Center" Foreground="#5D6D7E"/>
        <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" HorizontalAlignment="Right">
          <Button Name="ExportButton" Content="Export plan" Height="32" Padding="14,0" Margin="0,0,8,0"/>
          <Button Name="DryRunButton" Content="Preview commands" Height="32" Padding="14,0" Margin="0,0,8,0"/>
          <Button Name="InstallButton" Content="Install / open selected" Height="32" Padding="14,0"/>
        </StackPanel>
      </DockPanel>
    </Border>
  </Grid>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$appList = $window.FindName("AppList")
$searchBox = $window.FindName("SearchBox")
$categoryBox = $window.FindName("CategoryBox")
$installStateBox = $window.FindName("InstallStateBox")
$checkInstalledButton = $window.FindName("CheckInstalledButton")
$selectReadyButton = $window.FindName("SelectReadyButton")
$clearButton = $window.FindName("ClearButton")
$summaryText = $window.FindName("SummaryText")
$statusText = $window.FindName("StatusText")
$detailName = $window.FindName("DetailName")
$detailMeta = $window.FindName("DetailMeta")
$detailDescription = $window.FindName("DetailDescription")
$configPaths = $window.FindName("ConfigPaths")
$openOfficialButton = $window.FindName("OpenOfficialButton")
$openConfigButton = $window.FindName("OpenConfigButton")
$installProgress = $window.FindName("InstallProgress")
$queueList = $window.FindName("QueueList")
$installLogBox = $window.FindName("InstallLogBox")
$exportButton = $window.FindName("ExportButton")
$dryRunButton = $window.FindName("DryRunButton")
$installButton = $window.FindName("InstallButton")
$logDir = Join-Path $Root "logs"
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($apps)
$appList.ItemsSource = $view
$queueItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$queueList.ItemsSource = $queueItems
$script:SortColumn = $null
$script:SortDirection = [System.ComponentModel.ListSortDirection]::Ascending
$script:FilterQuery = ""
$script:FilterCategory = "All"
$script:FilterInstallState = "All states"

$categories = @("All") + (@($apps | ForEach-Object Category | Sort-Object -Unique))
foreach ($categoryName in $categories) {
    [void]$categoryBox.Items.Add($categoryName)
}
$categoryBox.SelectedIndex = 0

foreach ($stateName in @("All states", "Installed", "Not installed", "Unknown", "Unchecked")) {
    [void]$installStateBox.Items.Add($stateName)
}
$installStateBox.SelectedIndex = 0

function Update-Summary {
    $selected = @($apps | Where-Object Selected)
    $readyWinget = @($apps | Where-Object { $_.Type -eq "winget" -and $_.Status -eq "ready" })
    $installed = @($apps | Where-Object { $_.InstallState -eq "Installed" })
    $missing = @($apps | Where-Object { $_.InstallState -eq "Not installed" })
    $visibleCount = 0
    foreach ($item in $view) {
        $visibleCount += 1
    }
    $summaryText.Text = "{0} apps in catalog | {1} visible | {2} installed | {3} missing | {4} ready winget apps | {5} selected" -f $apps.Count, $visibleCount, $installed.Count, $missing.Count, $readyWinget.Count, $selected.Count
    $statusText.Text = "Selected: " + ($selected.Name -join ", ")
    if ($selected.Count -eq 0) {
        $statusText.Text = "No apps selected."
    }
}

function Apply-Filter {
    $script:FilterQuery = $searchBox.Text.Trim().ToLowerInvariant()
    $script:FilterCategory = [string]$categoryBox.SelectedItem
    if ([string]::IsNullOrWhiteSpace($script:FilterCategory)) {
        $script:FilterCategory = "All"
    }
    $script:FilterInstallState = [string]$installStateBox.SelectedItem
    if ([string]::IsNullOrWhiteSpace($script:FilterInstallState)) {
        $script:FilterInstallState = "All states"
    }

    $view.Filter = {
        param($item)
        $nameText = ([string]$item.Name).ToLowerInvariant()
        $categoryText = ([string]$item.Category).ToLowerInvariant()
        $packageText = ([string]$item.Source).ToLowerInvariant()
        $matchesQuery = [string]::IsNullOrWhiteSpace($script:FilterQuery) -or
            $nameText.Contains($script:FilterQuery) -or
            $categoryText.Contains($script:FilterQuery) -or
            $packageText.Contains($script:FilterQuery)
        $matchesCategory = $script:FilterCategory -eq "All" -or $item.Category -eq $script:FilterCategory
        $matchesInstallState = $script:FilterInstallState -eq "All states" -or $item.InstallState -eq $script:FilterInstallState
        return $matchesQuery -and $matchesCategory -and $matchesInstallState
    }
    $view.Refresh()
    Update-Summary
}

function Apply-Sort([string]$propertyName) {
    if ([string]::IsNullOrWhiteSpace($propertyName)) { return }

    if ($script:SortColumn -eq $propertyName) {
        if ($script:SortDirection -eq [System.ComponentModel.ListSortDirection]::Ascending) {
            $script:SortDirection = [System.ComponentModel.ListSortDirection]::Descending
        }
        else {
            $script:SortDirection = [System.ComponentModel.ListSortDirection]::Ascending
        }
    }
    else {
        $script:SortColumn = $propertyName
        $script:SortDirection = [System.ComponentModel.ListSortDirection]::Ascending
    }

    $view.SortDescriptions.Clear()
    $view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription($script:SortColumn, $script:SortDirection)))
    if ($script:SortColumn -ne "Name") {
        $view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription("Name", [System.ComponentModel.ListSortDirection]::Ascending)))
    }
    $view.Refresh()
}

function Get-SelectedApps {
    @($apps | Where-Object Selected)
}

function Show-AppDetail($item) {
    if (-not $item) { return }
    $detailName.Text = $item.Name
    $detailMeta.Text = "{0} | {1} | {2}" -f $item.Category, $item.Type, $item.Status
    $detailDescription.Text = $item.Description
    $paths = @($item.Raw.config.paths)
    if ($paths.Count -eq 0) {
        $configPaths.Text = "No config paths yet."
    }
    else {
        $configPaths.Text = ($paths -join [Environment]::NewLine)
    }
}

function Resolve-ConfigPath([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }

    $expanded = [Environment]::ExpandEnvironmentVariables($path)
    $matches = @(Get-ChildItem -Path $expanded -Force -ErrorAction SilentlyContinue)
    if ($matches.Count -gt 0) {
        return $matches[0].FullName
    }

    if (Test-Path -LiteralPath $expanded) {
        return (Resolve-Path -LiteralPath $expanded).Path
    }

    $parent = Split-Path -Parent $expanded
    if ($parent -and (Test-Path -LiteralPath $parent)) {
        return $parent
    }

    return $null
}

function Test-AppInstalled($item) {
    if ($item.Type -ne "winget" -or [string]::IsNullOrWhiteSpace($item.Raw.install.packageId)) {
        return "Unknown"
    }

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        return "Unknown"
    }

    $output = & winget list --id $item.Raw.install.packageId --exact --disable-interactivity 2>&1 | Out-String
    if ($output -match [regex]::Escape($item.Raw.install.packageId)) {
        return "Installed"
    }

    return "Not installed"
}

function Refresh-InstallStates($targetApps) {
    $targetList = @($targetApps)
    if ($targetList.Count -eq 0) { return }

    $checkInstalledButton.IsEnabled = $false
    $statusText.Text = "Checking installed apps..."

    try {
        $index = 0
        foreach ($item in $targetList) {
            $index += 1
            $item.InstallState = "Checking"
            $appList.Items.Refresh()
            $statusText.Text = "Checking {0} of {1}: {2}" -f $index, $targetList.Count, $item.Name
            [System.Windows.Forms.Application]::DoEvents()

            $item.InstallState = Test-AppInstalled $item
            $appList.Items.Refresh()
        }
    }
    finally {
        $checkInstalledButton.IsEnabled = $true
        $view.Refresh()
        Update-Summary
    }
}

function Export-Plan($selectedApps, [switch]$PreviewOnly) {
    $planDir = Join-Path $Root "output"
    if (-not (Test-Path -LiteralPath $planDir)) {
        [void](New-Item -ItemType Directory -Path $planDir)
    }
    $planPath = Join-Path $planDir "install-plan.json"
    $selectedApps |
        Select-Object Id, Name, Category, Type, Status, Source |
        ConvertTo-Json -Depth 5 |
        Set-Content -LiteralPath $planPath -Encoding UTF8

    if ($PreviewOnly) {
        $commands = foreach ($item in $selectedApps) {
            if ($item.Type -eq "winget") {
                $command = "winget install --id {0} --exact --accept-package-agreements --accept-source-agreements" -f $item.Raw.install.packageId
                if (-not [string]::IsNullOrWhiteSpace($item.Raw.install.scope)) {
                    $command += " --scope " + $item.Raw.install.scope
                }
                $command
            }
            elseif ($item.Type -eq "manual") {
                if ($item.Raw.install.action -eq "download" -or $item.Raw.install.url -match '\.(exe|msi|msix|appx)(\?.*)?$') {
                    "Download and run {0}" -f $item.Raw.install.url
                }
                else {
                    "Open {0}" -f $item.Raw.install.url
                }
            }
            elseif ($item.Type -eq "offline") {
                "Run local installer {0}" -f $item.Raw.install.installer
            }
        }
        $commandPath = Join-Path $planDir "winget-preview.txt"
        $commands | Set-Content -LiteralPath $commandPath -Encoding UTF8
        return $commandPath
    }

    return $planPath
}

function Write-SelectedAppIdsFile($selectedApps) {
    $planDir = Join-Path $Root "output"
    if (-not (Test-Path -LiteralPath $planDir)) {
        [void](New-Item -ItemType Directory -Path $planDir)
    }

    $idsPath = Join-Path $planDir "selected-app-ids.txt"
    @($selectedApps | ForEach-Object Id) | Set-Content -LiteralPath $idsPath -Encoding UTF8
    return $idsPath
}

function Append-InstallLog([string]$message) {
    if ([string]::IsNullOrWhiteSpace($message)) { return }

    $installLogBox.AppendText($message + [Environment]::NewLine)
    $installLogBox.ScrollToEnd()
    [System.Windows.Forms.Application]::DoEvents()
}

function Get-InstallActionText($item) {
    if ($item.Type -eq "winget") {
        $command = "winget install --id {0} --exact --accept-package-agreements --accept-source-agreements" -f $item.Raw.install.packageId
        if (-not [string]::IsNullOrWhiteSpace($item.Raw.install.scope)) {
            $command += " --scope " + $item.Raw.install.scope
        }
        return $command
    }

    if ($item.Type -eq "manual") {
        if ($item.Raw.install.action -eq "download" -or $item.Raw.install.url -match '\.(exe|msi|msix|appx)(\?.*)?$') {
            return "download and run " + $item.Raw.install.url
        }
        return "open " + $item.Raw.install.url
    }

    if ($item.Type -eq "offline") {
        return "run local installer " + $item.Raw.install.installer
    }

    return "unknown install action"
}

$searchBox.Add_TextChanged({ Apply-Filter })
$categoryBox.Add_SelectionChanged({ Apply-Filter })
$installStateBox.Add_SelectionChanged({ Apply-Filter })
$appList.Add_SelectionChanged({ Show-AppDetail $appList.SelectedItem })

$openOfficialButton.Add_Click({
    $item = $appList.SelectedItem
    if (-not $item) {
        [System.Windows.MessageBox]::Show("Select an app first.", "Setup Hub") | Out-Null
        return
    }

    $url = $item.Raw.install.officialUrl
    if ([string]::IsNullOrWhiteSpace($url)) {
        $url = $item.Raw.install.url
    }

    if ([string]::IsNullOrWhiteSpace($url)) {
        [System.Windows.MessageBox]::Show("No official site or download page is saved for this app yet.", "Setup Hub") | Out-Null
        return
    }

    Start-Process $url
})

$openConfigButton.Add_Click({
    $item = $appList.SelectedItem
    if (-not $item) {
        [System.Windows.MessageBox]::Show("Select an app first.", "Setup Hub") | Out-Null
        return
    }

    $paths = @($item.Raw.config.paths)
    if ($paths.Count -eq 0) {
        [System.Windows.MessageBox]::Show("This app has no config paths yet.", "Setup Hub") | Out-Null
        return
    }

    foreach ($path in $paths) {
        $resolved = Resolve-ConfigPath $path
        if ($resolved) {
            Start-Process explorer.exe -ArgumentList "`"$resolved`""
            return
        }
    }

    [System.Windows.MessageBox]::Show("None of the saved config paths exist on this computer yet.", "Setup Hub") | Out-Null
})

$appList.AddHandler(
    [System.Windows.Controls.GridViewColumnHeader]::ClickEvent,
    [System.Windows.RoutedEventHandler]{
        param($sender, $eventArgs)

        $headerSource = $eventArgs.OriginalSource
        while ($headerSource -and -not ($headerSource -is [System.Windows.Controls.GridViewColumnHeader])) {
            $headerSource = [System.Windows.Media.VisualTreeHelper]::GetParent($headerSource)
        }

        if (-not $headerSource -or -not $headerSource.Column) { return }

        $header = [string]$headerSource.Column.Header
        $propertyName = switch ($header) {
            "Name" { "Name" }
            "Category" { "Category" }
            "Install" { "Type" }
            "Installed" { "InstallState" }
            "Status" { "Status" }
            "Package / Source" { "Source" }
            default { $null }
        }

        Apply-Sort $propertyName
    }
)

foreach ($column in $appList.View.Columns) {
    $header = [string]$column.Header
    $propertyName = switch ($header) {
        "Name" { "Name" }
        "Category" { "Category" }
        "Install" { "Type" }
        "Installed" { "InstallState" }
        "Status" { "Status" }
        "Package / Source" { "Source" }
        default { $null }
    }

    if ($propertyName) {
        $column.Header = $header
    }
}

$selectReadyButton.Add_Click({
    foreach ($item in $apps) {
        $item.Selected = ($item.Type -eq "winget" -and $item.Status -eq "ready")
    }
    $appList.Items.Refresh()
    Update-Summary
})

$checkInstalledButton.Add_Click({
    Refresh-InstallStates $apps
})

$clearButton.Add_Click({
    $searchBox.Text = ""
    $categoryBox.SelectedIndex = 0
    $installStateBox.SelectedIndex = 0
    foreach ($item in $apps) {
        $item.Selected = $false
    }
    $appList.Items.Refresh()
    Update-Summary
})

$exportButton.Add_Click({
    $selected = Get-SelectedApps
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Select at least one app first.", "Setup Hub") | Out-Null
        return
    }
    $path = Export-Plan $selected
    [System.Windows.MessageBox]::Show("Plan exported to $path", "Setup Hub") | Out-Null
})

$dryRunButton.Add_Click({
    $selected = Get-SelectedApps
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Select at least one app first.", "Setup Hub") | Out-Null
        return
    }
    $path = Export-Plan $selected -PreviewOnly
    [System.Windows.MessageBox]::Show("Preview exported to $path", "Setup Hub") | Out-Null
})

$script:InstallQueue = @()
$script:InstallQueueIndex = 0
$script:CurrentInstallProcess = $null
$script:CurrentInstallLogPath = $null
$script:CurrentInstallLogLength = 0
$script:CurrentQueueItem = $null

function Complete-InstallQueue([bool]$failed, [string]$message) {
    if ($script:InstallTimer) {
        $script:InstallTimer.Stop()
    }

    $script:CurrentInstallProcess = $null
    $script:CurrentInstallLogPath = $null
    $script:CurrentInstallLogLength = 0
    $script:CurrentQueueItem = $null

    $installButton.IsEnabled = $true
    $checkInstalledButton.IsEnabled = $true
    Update-Summary

    if ($failed) {
        $errorPath = Join-Path $logDir ("install-error-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
        $installLogBox.Text | Set-Content -LiteralPath $errorPath -Encoding UTF8
        [System.Windows.MessageBox]::Show(("Install failed. Error log saved to:`n{0}`n`n{1}" -f $errorPath, $message), "Setup Hub") | Out-Null
        return
    }

    $installProgress.Value = 100
    $statusText.Text = "Install queue finished."
    [System.Windows.MessageBox]::Show("Install queue finished.", "Setup Hub") | Out-Null
}

function Start-NextInstallQueueItem {
    if ($script:InstallQueueIndex -ge $script:InstallQueue.Count) {
        Complete-InstallQueue $false ""
        return
    }

    $item = $script:InstallQueue[$script:InstallQueueIndex]
    $script:CurrentQueueItem = @($queueItems | Where-Object { $_.Id -eq $item.Id })[0]
    if ($script:CurrentQueueItem) {
        $script:CurrentQueueItem.Status = "Running"
        $queueList.Items.Refresh()
    }

    $statusText.Text = "Installing or opening: " + $item.Name
    Append-InstallLog ("=== " + $item.Name + " ===")
    Append-InstallLog ("> " + (Get-InstallActionText $item))

    $idsPath = Write-SelectedAppIdsFile @($item)
    $script:CurrentInstallLogPath = Join-Path $logDir ("install-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + $item.Id + ".log")
    $script:CurrentInstallLogLength = 0
    $runnerPath = Join-Path $logDir ("run-install-" + [guid]::NewGuid().ToString("N") + ".ps1")
    $installScript = Join-Path $Root "scripts\Install-Apps.ps1"

    @(
        '$ErrorActionPreference = "Stop"'
        '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8'
        '& "' + $installScript + '" -CatalogPath "' + $CatalogPath + '" -AppIdsFile "' + $idsPath + '" *>&1 | Tee-Object -FilePath "' + $script:CurrentInstallLogPath + '"'
        'if ($LASTEXITCODE -ne $null) { exit $LASTEXITCODE }'
    ) | Set-Content -LiteralPath $runnerPath -Encoding UTF8

    $powershellPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $powershellPath
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`""
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $script:CurrentInstallProcess = New-Object System.Diagnostics.Process
    $script:CurrentInstallProcess.StartInfo = $startInfo
    [void]$script:CurrentInstallProcess.Start()
}

function Update-InstallQueueFromTimer {
    if ($script:CurrentInstallLogPath -and (Test-Path -LiteralPath $script:CurrentInstallLogPath)) {
        $text = [System.IO.File]::ReadAllText($script:CurrentInstallLogPath, [System.Text.Encoding]::UTF8)
        if ($text.Length -gt $script:CurrentInstallLogLength) {
            $newText = $text.Substring($script:CurrentInstallLogLength)
            $script:CurrentInstallLogLength = $text.Length
            $installLogBox.AppendText($newText)
            if (-not $newText.EndsWith([Environment]::NewLine)) {
                $installLogBox.AppendText([Environment]::NewLine)
            }
            $installLogBox.ScrollToEnd()
        }
    }

    if (-not $script:CurrentInstallProcess) { return }
    if (-not $script:CurrentInstallProcess.HasExited) { return }

    $exitCode = $script:CurrentInstallProcess.ExitCode
    if ($exitCode -eq 0) {
        if ($script:CurrentQueueItem) {
            $script:CurrentQueueItem.Status = "Done"
            $queueList.Items.Refresh()
        }
        $script:InstallQueueIndex += 1
        $installProgress.Value = [Math]::Round(($script:InstallQueueIndex / $script:InstallQueue.Count) * 100, 0)
        Start-NextInstallQueueItem
        return
    }

    if ($script:CurrentQueueItem) {
        $script:CurrentQueueItem.Status = "Failed"
        $queueList.Items.Refresh()
    }
    Complete-InstallQueue $true ("Install action failed with exit code " + $exitCode)
}

$script:InstallTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:InstallTimer.Interval = [TimeSpan]::FromMilliseconds(500)
$script:InstallTimer.Add_Tick({ Update-InstallQueueFromTimer })

$installButton.Add_Click({
    try {
        $selected = @(Get-SelectedApps)
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Select at least one app first.", "Setup Hub") | Out-Null
            return
        }

        $message = "Install or open {0} selected apps now?" -f $selected.Count
        $result = [System.Windows.MessageBox]::Show($message, "Setup Hub", "YesNo", "Question")
        if ($result -ne "Yes") { return }

        $installButton.IsEnabled = $false
        $checkInstalledButton.IsEnabled = $false
        $queueItems.Clear()
        $installLogBox.Clear()
        $installProgress.Value = 0

        foreach ($item in $selected) {
            $queueItems.Add([pscustomobject]@{
                Id = $item.Id
                Name = $item.Name
                Status = "Queued"
            })
        }

        $script:InstallQueue = $selected
        $script:InstallQueueIndex = 0
        $script:CurrentInstallProcess = $null
        $script:CurrentInstallLogPath = $null
        $script:CurrentInstallLogLength = 0
        $script:CurrentQueueItem = $null
        Start-NextInstallQueueItem
        $script:InstallTimer.Start()
    }
    catch {
        $errorPath = Join-Path $logDir ("install-error-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
        (($installLogBox.Text + [Environment]::NewLine + ($_ | Out-String))) | Set-Content -LiteralPath $errorPath -Encoding UTF8
        [System.Windows.MessageBox]::Show(("Install failed. Error log saved to:`n{0}`n`n{1}" -f $errorPath, $_.Exception.Message), "Setup Hub") | Out-Null
        $installButton.IsEnabled = $true
        $checkInstalledButton.IsEnabled = $true
        Update-Summary
    }
})

foreach ($item in $apps) {
    $item.PSObject.Properties["Selected"].Value = $false
}

Apply-Filter
Apply-Sort "Category"
$view.Refresh()
Update-Summary

[void]$window.ShowDialog()
