# matlab-vlc

Control VLC from a MATLAB script

VLC actions such as play, pause, stop, next, previous, etc. are defined as class methods.
VLC settings such as Loop, Random, Repeat and Fullscreen are exposed to MATLAB and can be accessed with set() and get().
Informations about the current file can be retrieved through the 'Current' property (length, position, metadata, etc).

### Methods
- `play()` or `play('filename')`: resume playback or play "filename"
- `add('filename')`: add "filename" to the playlist
- `pause()`: pause playback
- `stop()`: stop playback
- `next()`: play next track
- `prev()`: play previous track
- `clear()`: empty the playlist
- `seek(position)`: seek to position (in seconds)

### Properties
- Port (read only)
- Version (read only)
- Status (read only)
- Current (read only)
- Playlist (read only)
- Loop
- Random
- Repeat
- Fullscreen (write only)

## Example
```
>> v = VLC()

v = 

  VLC with properties:

        Port: 4212
     Version: '2.2.2 Weatherwax'
      Status: 'stopped'
     Current: []
    Playlist: [1x1 struct]
        Loop: 'off'
      Random: 'off'
      Repeat: 'off'

>> v.play('/Users/Lea/Desktop/3905.aif') 
>> v

v = 

  VLC with properties:

        Port: 4212
     Version: '2.2.2 Weatherwax'
      Status: 'playing'
     Current: [1x1 struct]
    Playlist: [1x1 struct]
        Loop: 'off'
      Random: 'off'
      Repeat: 'off'

>> v.Current

ans = 

          ID: 4
      Length: 77.0903
        Meta: [1x1 struct]
    Position: 8.8021

>> v.stop()
```
