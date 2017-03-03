# Monitor Sonos

This application monitors sonos speakers in the current network, 
as well as saving the musics as they appear, and actively lowering 
the volume by one unit every few seconds.

## Install and run

```
$ bundle install
$ ./ubin/monitor
```

You will see something similar to this:

```
+--------------+------------------+--------+-----------+-------+-----------------+
|                   Monitoring Sonos Nodes in current network                    |
+--------------+------------------+--------+-----------+-------+-----------------+
| ip           | name             | volume | artist    | title | position        |
+--------------+------------------+--------+-----------+-------+-----------------+
| 10.1.1.1     | Node_name_01     | 17     | Radiohead | Creep | 0:02:47/0:03:58 |
| 10.1.1.2     | Node_name_02     | 10     | Radiohead | Creep | 0:02:46/0:03:58 |
| 10.1.1.3     | Node_name_03     | 17     | Radiohead | Creep | 0:02:53/0:03:58 |
| 10.1.1.4     | Node_name_04     | 17     | n/a       | n/a   | n/a             |
+--------------+------------------+--------+-----------+-------+-----------------+
```

## Actively monitor and lower volume

```
$ ./ubin/lower-sound <optionaly set the volume>
```

## Logs and music lists

All the logs and music list will be saved to files under the logs directory.

i.e.:
```
logs/
├── application.log
└── music.log
```