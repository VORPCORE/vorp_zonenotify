# VORP Zonenotify

RedM zone notification system for [VORP Core](https://vorpcore.mintlify.app/introduction)

---

## Features

1. Displays a top notification when you enter towns, districts, states, and others.
2. Displays the time within the notification
3. Displays the temperature within the notification
4. 233+ Native Zones!
5. Config based native notificaton or a custom Vue.js notification
6. Dynamic colors according to time and temperature

---

**Custom**
<img alt="image" src="https://user-images.githubusercontent.com/10902965/170663856-e6b11c13-df2e-49e7-957a-10bc4bec9774.png">

**Native**
<img alt="image" src="https://user-images.githubusercontent.com/10902965/170857584-2bca2214-e671-4c7d-87f8-acd5022f02c3.png">

**Dynamic Color**

<img alt="image" src="https://github.com/user-attachments/assets/3ad927e1-efe3-4c03-902a-7b318eed2390">

## Installation
1. Download this repo/codebase
2. Extract and place `vorp_zonenotify` into your `resources` folder
3. Add `ensure vorp_zonenotify` to your `server.cfg` file
4. Restart your server

## How-to-configure
All configurations available in `config.lua`

- NativeZones = True/False (If you want to use the native notification of the custom one)
- Notification.TimeShowing = How long the notification will display.
- Config.EnableKeyCheck = To get zone information when you press a key (Config.Key)
- Config.ShowTime = To show the time in the UI (Config.TimeDayColor/Config.TimeNightColor)
- Config.ShowTemperature = To show the temperature in the UI (Config.TemperatureColdDegree/Config.TemperatureHotColor/Config.TemperatureColdColor)
- Config.ShowWind = To show the wind in the UI (Config.WindColor)

## TODO
- Add locales
- Migrate vue cdn to local vendor

## Dependency
 - [VORP Core](https://github.com/VORPCORE/vorp_core-lua)

## Support
[VORP Core Discord](https://discord.gg/JjNYMnDKMf)
