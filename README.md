# PAI - Personal AI

PAI is an open source iOS app aim to let developer and AI enthusiast test and develop voice/ video chat application with AI.
PAI app leverage on LiveKit for RTC streaming for better audio and video quality and noise reduction.

User can connect PAI app to their backend using their private network for a personal AI experience.

If you like the project, consider leaving a star.

## Feature
- Video and Voice chat
- Hand Free talking
- Transcription
- Screensharing
- Tools usage


Install via TestFlight here
[TestFlight](https://testflight.apple.com/join/ES3jfr1r)

## Setup

The app can be found from App store. To set up the backend needed to run the app please refer to this repo [PAI-Agent](https://github.com/remichu-ai/pai-agent.git)


## In-app Setup

Following is the guide for the setting inside the PAI app and what you can change:


### Home
<img src="https://github.com/remichu-ai/pai/blob/main/images/Home.PNG" alt="Home" width="396" height="860.4">


- Press the Setting Icon on the top right corner to enter the URL to your backend.
- Hand-free mode toggle: hand-free mode will automatically detect if you have finished talking and signal to backend to answer

### Basic Setting
<img src="https://github.com/remichu-ai/pai/blob/main/images/SettingURL.jpeg" alt="Home" width="396" height="860.4">

The most important setting for the app to work is to have the ServerURL and Authentication URL. 
Please fill in your server IP address similar to the picture with port 7880 (default Livekit port) and port 3111 for authentication.
The IP address in the picture (10.10.10.10) is just illustration only. As the software is self-hosted, you can must find the IP to access your backend in your local network or your other VPN service.


### Voice Chat
<img src="https://github.com/remichu-ai/pai/blob/main/images/VideoChat.PNG" alt="Home" width="396" height="860.4">

- Button in in the bottom contron bar from left to right: Mute, Video mode, Screen Share, Disconnect

- Touch on the `...` button to toggle Hand-free mode and turn on transcript


### Tool Setting
- If you have any tools configured at the backend, it will appear here.
- By default when application launch, all tool will be disabled.
<img src="https://github.com/remichu-ai/pai/blob/main/images/ToolSetting.PNG" alt="Home" width="396" height="860.4">

More setting can be further explored in the Setting Menu.
