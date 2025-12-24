param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$MusicPath,

    [Parameter(Position = 1)]
    [string]$Filter = '*.mp3'
)


Add-Type -AssemblyName PresentationCore

function Get-CurrentSong {
    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }
    
    $CurrentIndex = $(Get-trackNumber) - 1
    $song = $Global:playlistPlayer[$CurrentIndex].FullName

    return [string] $song
}

function Get-PreviewSong {
    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }
    
    
    $songIndex = $(Get-PlaybackAction).SongIndex
    if (
        ('Deactivated' -eq $(Get-RepeatModeStatus)) -and
        ('Deactivated' -eq $(Get-ShuffleModeStatus))
    ) {
        $songIndex = $songIndex - 2
    }

    $song = $Global:playlistPlayer[$songIndex - 1].FullName

    return [PSCustomObject]@{
        Song = [string] $song
        SongIndex = [int] $songIndex
    }
}

function Get-NextSong {
    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    $CurrentIndex = Get-trackNumber
    $songIndex = $CurrentIndex + 1
    $song = $Global:playlistPlayer[$songIndex].FullName

    return [string] $song
}

function Update-NextSong {
    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    $songIndex = $(Get-PlaybackAction).SongIndex
    $song = $Global:playlistPlayer[$songIndex].FullName

    return [PSCustomObject]@{
        Song = [string] $song
        SongIndex = [int] $songIndex
    }
}

function Get-SongByIndex {
    param (
        [int] $index
    )

    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    $songIndex = $index - 1
    $song = $Global:playlistPlayer[$songIndex].FullName
    return [string] $song
}

function Get-PlaybackTime {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Formatear como HH:MM:SS con dos dígitos en cada campo
    $duracionAtual = $Global:player.Position.TotalSeconds

    return $duracionAtual
}

function Get-trackNumber {
    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    # Eecogida el numero de la pista
    $songIndex = $Global:displayPlayer.CurrentsongTrackNumber

    return $songIndex
}

function Get-RepeatModeStatus {
    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    return $Global:displayPlayer.Repeat
}

function Set-RepeatModeStatus {
    param (
        [RepeatMode]$mode = [RepeatMode]::Deactivated
    )

    if ($null -eq $Global:displayPlayer) {
        throw 'Playlist no definido'
    }

    $Global:displayPlayer.Repeat = $mode
}

function Get-ShuffleModeStatus {
    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    return $Global:displayPlayer.Shuffle
}

function Set-ShuffleModeStatus {
    param (
        [ShuffleMode]$mode = [ShuffleMode]::Deactivated
    )

    if ($null -eq $Global:displayPlayer) {
        throw 'Playlist no definido'
    }

    $Global:displayPlayer.Shuffle = $mode
}

function Update-trackNumber {
    param(
        [int] $songIndex
    )

    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Actualiza el numero de la pista
    $Global:displayPlayer.CurrentsongTrackNumber = $songIndex
}

function Open-File {
    param (
        [string] $uri
    )
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    $Global:player.Open($([Uri]::new($uri)))
}

function Resize-Volume {
    param (
        [double] $volume
    )

    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    $Global:player.Volume = [math]::Min([math]::Max($Volume, 0), 1)
}

function Start-Player {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Reproduzir
    $Global:player.Play()
}

function Wait-StartPlayback {
    $inicio = [DateTime]::UtcNow
    $timeout = [TimeSpan]::FromSeconds(2)

    while (-not (Assert-PlaybackIsStarted)) {
        if ([DateTime]::UtcNow - $inicio -gt $timeout) {
            return $false
        }

        Start-Sleep -Milliseconds 5
    }

    return $true
}

function Stop-Player {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Reproduzir
    $Global:player.Stop()
}

function Suspend-Player {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Reproduzir
    $Global:player.Pause()
}

function Assert-PlaybackIsStarted {
    # No hay archivo cargado
    if (-not $Global:player.Source) { 
        return $false
    }

    # La posición ya avanzó
    if ($Global:player.Position.Ticks -ne 0) {
        return $true
    }

    return $false
}

function Start-Song {
    param (
        [string] $song
    )

    Open-File -uri $song

    Start-Player
}

function Start-CurrentSong {
    $song = Get-CurrentSong
    Start-Song -song $song

    $CurrentIndex = Get-trackNumber
    Update-trackNumber -songIndex $($CurrentIndex)
}

function Start-NextSong {
    $songIndex = $(Update-NextSong).SongIndex
    $song = $(Get-PreviewSong).Song
    if ($song) {
        Start-SongByIndex -index $songIndex

        Update-trackNumber -songIndex $songIndex
    }
}

function Start-PreviewSong {
    $songIndex = $(Get-PreviewSong).SongIndex
    $song = $(Get-PreviewSong).Song
    if ($song) {
        Start-SongByIndex -index $songIndex

        $CurrentIndex = Get-trackNumber
        Update-trackNumber -songIndex $($CurrentIndex)
    }
}

function Start-SongByIndex {
    param (
        [int] $index
    )

    $song = Get-SongByIndex -index $index
    if ($song) {
        Start-Song -song $song

        Update-trackNumber -songIndex $index
    }
}

function Get-DisplayInformation {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    if ([string]::IsNullOrEmpty($Global:displayPlayer)) {
        throw 'Display no definido'
    }

    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    $Global:displayPlayer.CurrentsongPath = $Global:player.Source.OriginalString
    $Global:displayPlayer.CurrentsongTime = Get-PlaybackTime
    $Global:displayPlayer.CurrentsongTotalTime = $Global:player.NaturalDuration.TimeSpan.TotalSeconds
    Update-trackNumber -songIndex $(Get-trackNumber + 1)
    $Global:displayPlayer.CurrentsongVolume = $Global:player.Volume
    $Global:displayPlayer.NextSong = $(
        $Global:playlistPlayer.Count -ge $Global:playlistPlayerStore.Count
    )
    $Global:displayPlayer.Repeat = Get-RepeatModeStatus
    $Global:displayPlayer.Shuffle = Get-ShuffleModeStatus
}

function Update-DisplayPlayer {
    Get-DisplayInformation

    $interfaceTextColor = $Global:colorSet.InterfaceText
    Write-Host "Pista actual: " -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host $($Global:displayPlayer.CurrentsongPath)

    Write-Host "Número de la pista: " -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host $(Get-trackNumber + 1)

    $CurrentsongTimeFormatted = ('{0:hh\:mm\:ss}' -f [TimeSpan]::FromSeconds([double]$Global:displayPlayer.CurrentsongTime))
    Write-Host 'Tiempo transcurrido: ' -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host $CurrentsongTimeFormatted

    $CurrentsongTotalTimeFormatted = ('{0:hh\:mm\:ss}' -f [TimeSpan]::FromSeconds([double]$Global:displayPlayer.CurrentsongTotalTime))
    Write-Host 'Tiempo total: ' -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host $CurrentsongTotalTimeFormatted

    Write-Host "Volumen actual: " -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host "$($Global:displayPlayer.CurrentsongVolume * 100)%"

    $Global:displayPlayer.Status = "Parado"
    if (-not $Global:player.naturalDuration.HasTimeSpan) {
        $Global:displayPlayer.Status = "Parado"
    } elseif ($Global:player.Position.Ticks -eq 0) {
        $Global:displayPlayer.Status = "Parado"
    } elseif (
        $Global:player.Position.Ticks -eq $Global:player.NaturalDuration.TimeSpan.Ticks
    ) {
        $Global:displayPlayer.Status = "Parado"
    } else {
        $Global:displayPlayer.Status = "Reproduciendo"

        $timePosition = $Global:player.Position.Ticks
        Start-Sleep -Milliseconds 200
        $newTimePosition = $Global:player.Position.Ticks
        if ($timePosition -eq $newTimePosition) {
            $Global:displayPlayer.Status = "Pausado"
        }
    }

    Write-Host "Estado actual: " -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host $($Global:displayPlayer.Status)

    Write-Host "Repetir: " -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host $($Global:displayPlayer.Repeat)

    Write-Host "Aleatorio: " -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host $($Global:displayPlayer.Shuffle)
    Write-Host `n

    Write-Host ('-' * 40)
    Write-Host "Playlist: " -ForegroundColor $interfaceTextColor
    Show-Playlist
    Write-Host `n

    Write-Host ('-' * 40)
    Write-Host "Opciones disponibles:" -NoNewline -ForegroundColor $interfaceTextColor
    Write-Host ("`n    " + ($featuresPlayer -join "`n    "))
    Write-Host `n

    Write-Host "Ctrl + C para salir del bucle" -ForegroundColor $interfaceTextColor
    Write-Host `n
}

function Show-DisplayPlayer {
    $duracion = -1

    Update-DisplayPlayer

    while ([math]::Floor(($Global:displayPlayer.CurrentsongTime)) -ne [math]::Floor(($Global:displayPlayer.CurrentsongTotalTime))) {
        Get-DisplayInformation

        $duracionAtual = [math]::Floor(($Global:displayPlayer.CurrentsongTime))

        if ($duracionAtual -ne $duracion) {
            Clear-Host
            Update-DisplayPlayer
            $duracion = $duracionAtual
        }
    }
}

function Get-PlaybackAction {
    $playNext = $false
    $songIndex = 1
    if ('Activated' -eq $(Get-RepeatModeStatus)) {
        $songIndex = $Global:displayPlayer.CurrentsongTrackNumber
        if ($songIndex -notin $Global:playlistPlayerStore) {
            $Global:playlistPlayerStore.Add($songIndex)
        }

        $playNext = $true
    } elseif ('Activated' -eq $(Get-ShuffleModeStatus)) {
        $SuffleSongIndex = (1..($global:playlistPlayer.Count) `
            | Where-Object {$_ -notin $Global:playlistPlayerStore}) `
            | Get-Random 

        if ($SuffleSongIndex) {
            if ($songIndex -notin $Global:playlistPlayerStore) {
                $Global:playlistPlayerStore.Add($songIndex)
            }

            $songIndex = $SuffleSongIndex
        }

        $playNext = $true
        if (-not $SuffleSongIndex) {
            $playNext = $false
        }
    } elseif ($Global:displayPlayer.NextSong) {
        $songIndex = $(Get-trackNumber) + 1
        if ($songIndex -notin $Global:playlistPlayerStore) {
            $Global:playlistPlayerStore.Add($songIndex)
        }

        $playNext = $true
    }

    return [PSCustomObject]@{
        PlayNext = $playNext
        SongIndex = $songIndex
    }
}

function Invoke-Player {
    $playNext = $true
    while ($playNext) {
        Clear-Host

        if (-not $Global:player.naturalDuration.HasTimeSpan) {
            $songIndex = 1
            Start-SongByIndex -index $songIndex
            Update-trackNumber -songIndex $songIndex
        } elseif ($Global:player.Position.Ticks -eq 0) {
            Start-Player
        } else {
            Start-Player
        }

        if (-not (Wait-StartPlayback)) {
            throw 'La reproducción no pudo iniciarse'
        }

        if ($null -eq $(Get-RepeatModeStatus)) {
            Set-RepeatModeStatus -mode 'Deactivated'
        }

        if ($null -eq $(Get-ShuffleModeStatus)) {
            Set-ShuffleModeStatus -mode 'Deactivated'
        }

        Show-DisplayPlayer

        $playNext = $(Get-PlaybackAction).PlayNext
        $songIndex = $(Get-PlaybackAction).SongIndex

        if ($playNext) {
            Start-SongByIndex -index $songIndex

            if (-not (Wait-StartPlayback)) {
                throw 'La reproducción no pudo iniciarse'
            }
        }
    }
}

function Add-MusicToPlaylist {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$MusicPath,

        [Parameter(Position = 1)]
        [string]$Filter = '*.mp3'
    )

    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    # Agregar el array para la lista de las músicas
    $Global:playlistPlayer += Get-ChildItem -Path "$MusicPath" -Filter $Filter `
        | Where-Object {$_.FullName}

    # Convertir el array a ArrayList
    $Global:playlistPlayer = [System.Collections.ArrayList]::new(
        $($Global:playlistPlayer | Where-Object {$_.FullName})
    )
}

function Remove-MusicToPlaylist {
    param (
        [int] $songIndex
    )

    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    # Remover el elemento por índice
    $global:playlistPlayer.RemoveAt($($songIndex - 1))
}

function Show-Playlist {
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [switch] $all
    )

    $songIndex = Get-trackNumber

    $offsetsong = 10
    if ($all) {
        $offsetsong = $global:playlistPlayer.Count
    }

    $playlist = Get-Playlist -songIndex $($songIndex - 1) -offsetsong $offsetsong

    $defaultBackgroundColor = [Console]::BackgroundColor
    $defaultForegroundColor = [Console]::ForegroundColor

    $halfOffset = [System.Math]::Round($($offsetsong / 2))
    $startIndexsong = $songIndex - $halfOffset
    if ($startIndexsong -le 0) {
        $startIndexsong = 1
    }

    $internalTotal = $startIndexsong + $offsetsong
    $displayIndex = 1
    while ($startIndexsong -lt $internalTotal) {

        $backgroundColor = $defaultBackgroundColor
        $forekgroundColor = $defaultForegroundColor

        if ($startIndexsong -eq $songIndex) {
            $backgroundColor = $Global:colorSet.DisplayBackground
            $forekgroundColor = $Global:colorSet.DisplayText
        }

        Write-Host (
            ($startIndexsong).ToString().PadRight(6) + " | "
        ) -NoNewline

        Write-Host $playlist[$displayIndex - 1].FullName `
            -BackgroundColor $backgroundColor `
            -ForegroundColor $forekgroundColor

        $startIndexsong++
        $displayIndex++
    }
}

function Get-Playlist {
    param(
        [int] $songIndex,
        [int] $offsetsong
    )

    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    if ($offsetsong -le 0) {
        throw 'El límite no puede ser igual o menos de cero'
    }

    $startIndexsong = 0
    $endIndexsong = $offsetsong
    $halfOffset = [System.Math]::Round($($offsetsong / 2))
    $startIndexsong = $songIndex - $halfOffset
    $endIndexsong = $startIndexsong + $offsetsong

    if ($startIndexsong -lt 0) {
        $startIndexsong = 0
        $endIndexsong = $offsetsong
    }

    if (
        ($endIndexsong -gt $Global:playlistPlayer.Count) -and
        ($endIndexsong -ne $offsetsong)
    ) {
        $endIndexsong = $Global:playlistPlayer.Count
    }

    return $Global:playlistPlayer[$startIndexsong..$endIndexsong]
}

if ($player) {
    $Global:player.Close()
    $Global:player = $null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

$player = New-Object System.Windows.Media.MediaPlayer

Resize-Volume -volume 1.0

$displayPlayer = [PSCustomObject]@{
    CurrentsongPath        = $null
    CurrentsongTime        = $null
    CurrentsongTotalTime   = $null
    CurrentsongTrackNumber = $null
    CurrentsongVolume      = $null
    NextSong               = $null
    Status                 = $null
    Repeat                 = $null
    Shuffle                = $null
}

enum RepeatMode {
    Deactivated
    Activated
}

enum ShuffleMode {
    Deactivated
    Activated
}

$featuresPlayer = @(
    "Invoke-Player",
    "Start-Song [[-song] <string>]",
    "Start-SongByIndex [[-index] <int>]",
    "Start-NextSong",
    "Start-PreviewSong",
    "Start-Player",
    "Suspend-Player",
    "Stop-Player",
    "Add-MusicToPlaylist [-MusicPath] <string> [[-Filter] <string>]",
    "Remove-MusicToPlaylist [[-songIndex] <string>]",
    "Show-Playlist [-all]",
    "Resize-Volume [[-volume] <double>]",
    "Set-RepeatModeStatus [[-mode] 'Deactivated' -or 'Activated']",
    "Set-ShuffleModeStatus [[-mode] 'Deactivated' -or 'Activated']"
)

$colorSet = [PSCustomObject]@{
    InterfaceText = 'Yellow'
    InterfaceBackground = 'Black'
    DisplayText = 'Black'
    DisplayBackground = 'Yellow'
}

if ($playlistPlayer) {
    $Global:playlistPlayer = $null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

# Crear el array para la lista de las músicas
$playlistPlayer += Get-ChildItem -Path "$MusicPath" -Filter $Filter `
    | Where-Object {$_.FullName}

if (-not $playlistPlayer) {
    throw 'No hay archivos en este camino'
}

# Convertir el array a ArrayList
$playlistPlayer = [System.Collections.ArrayList]::new(
    $($playlistPlayer | Where-Object {$_.FullName})
)

if (-not $playlistPlayer) {
    throw 'No hay archivos en este camino'
}

$playlistPlayerStore = [System.Collections.ArrayList]::new()

Invoke-Player

Start-Sleep -Seconds 2
Clear-Host
Show-DisplayPlayer
