# Puctee

Puctee is a social planning and event management iOS application designed to help users organize and participate in plans with friends, manage invitations, track locations, and build trust within their social circle.

## Features

-   **User Authentication:** Secure sign-up and login flows.
-   **Plan Creation & Management:** Create, edit, and manage social plans with friends.
-   **Friend Management:** Add, remove, and manage friends within the app.
-   **Notifications:** Receive and manage notifications related to plans and friend requests.
-   **Location Tracking:** Real-time location sharing for participants within a plan (likely opt-in).
-   **Trust Statistics:** Features to build and display trust levels among users.
-   **User Profiles:** View and manage personal profiles and friend lists.
-   **Intuitive UI:** Built with SwiftUI for a modern and responsive user experience.

## Technologies Used

-   **Swift:** The primary programming language.
-   **SwiftUI:** Apple's declarative UI framework for building native iOS applications.
-   **Xcode:** The integrated development environment (IDE) for macOS.
-   **Swift Package Manager:** For dependency management (indicated by `Package.resolved`).
-   **Networking:** Custom API client for interacting with backend services (e.g., authentication, plans, users, friends, location services).
-   **Keychain:** For secure storage of sensitive user data (e.g., authentication tokens).
-   **JWT:** JSON Web Token handling for secure API communication.

## Installation

To get a local copy up and running, follow these simple steps.

### Prerequisites

-   Xcode (latest stable version recommended)
-   macOS

### Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/Puctee.git
    cd Puctee/frontend/puctee
    ```

2.  **Open the project in Xcode:**
    Open the `puctee.xcodeproj` file located in the `frontend/puctee` directory.

3.  **Resolve Swift Packages:**
    Xcode should automatically resolve any Swift Package Manager dependencies. If not, go to `File > Packages > Resolve Package Versions`.

4.  **Configure Environment (if applicable):**
    If the project requires specific API keys or environment variables, you may need to configure them. Check for any `Environment` files or instructions within the project.

5.  **Build the Project:**
    In Xcode, go to `Product > Build` or use the shortcut `⌘B`.

6.  **Select a Target and Run:**
    Select a simulator or a connected iOS device as the run target in Xcode and click the 'Run' button (▶️).

## Usage

Once the application is running on a simulator or device:

1.  **Sign Up/Log In:** Create a new account or log in with existing credentials.
2.  **Explore Home Screen:** View upcoming plans and notifications.
3.  **Create a Plan:** Use the plan editor to set up new events, invite friends, and define details.
4.  **Manage Friends:** Add new friends and view your existing friend list.
5.  **View Profiles:** Check out user profiles and trust statistics.

## Project Structure

-   `puctee/App/`: Main application entry point and routing.
-   `puctee/Assets.xcassets/`: Contains all image assets and app icons.
-   `puctee/Entities/`: Core data models for the application (e.g., `Plan`, `User`, `Location`).
-   `puctee/Environment/`: Environment-specific configurations.
-   `puctee/Mock/`: Sample data for development and testing.
-   `puctee/Utils/`: Utility classes including networking, keychain management, and managers for various app functionalities.
-   `puctee/Views/`: SwiftUI views organized by feature (e.g., `Auth`, `Home`, `PlanEditor`, `Profile`).

## Contributing

Contributions are welcome! Please fork the repository and create a pull request with your changes. Ensure your code adheres to the existing style and passes all tests.

## License

[Specify your license here, e.g., MIT License]