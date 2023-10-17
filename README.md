# Brain2Bot MATLAB App

The application provides a user-friendly GUI to demonstrate the integration of real-time processing of EEG signals acquired using BrainVision device and control of Kinova Jaco robotic arm.

## Features

- **Real and Virtual Modes**: The app can operate in either 'Real' mode, where it interfaces with actual EEG hardware and a robotic arm, or 'Virtual' mode for simulations.
- **Task Sequences**: Users can execute a sequence of tasks including picking up a bottle, pouring, and drinking.
- **Error Handling**: In case of any unexpected errors during robot task execution, the app provides detailed error messages to help with troubleshooting.
- **Test Modes**: The application offers the option to run in test mode, simulating EEG outputs for development and debugging purposes.
- **Interactive GUI**: A comprehensive graphical interface provides real-time feedback, video playback, and interactive controls for users.

## Setup

1. Clone the repository:

```
git clone https://github.com/heybshin/brain2bot-matlab-app.git
```

2. Open MATLAB and navigate to the directory containing the app.
3. Run the `brain2bot.m` script to launch the application.
4. Follow the on-screen instructions to operate in either Real or Virtual mode.

## Dependencies

This application relies on several external tools and libraries for its functionality:

- **MATLAB**: The primary platform for this application. The app has been tested and developed using versions 2021b and 2022b of MATLAB.
- **Kinova MATLAB API Wrapper**: This library, available [here](https://github.com/Kinovarobotics/matlab_Kinovaapi_wrapper), provides the necessary tools to interface with Kinova's robotic arms, particularly the Jaco SDK. Also provided in this repository, for reference.
- **BBCI Public**: An essential toolset for EEG data acquisition and processing. You can access and set it up from their GitHub repository [here](https://github.com/bbci/bbci_public).

Ensure you have all these dependencies set up and correctly configured before attempting to run the Brain2Bot application.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
