# TravelWise

TravelWise is a full-stack travel planning platform for creating trips, coordinating
travellers, managing budgets, planning activities, assessing risks, and tracking
travel-readiness tasks.

The repository contains:

- An ASP.NET Core 8 Web API.
- A React 19/Vite web application.
- A Flutter mobile application.
- Entity Framework Core migrations for Supabase PostgreSQL.

## Features

### Trip management

- Create, view, edit, and delete trips.
- Track destination, dates, objective, currency, and planning status.
- Use the same trip across budgets, activities, risk assessments, readiness tasks,
  and collaboration.

### Budget and expense management

- Create one budget for a trip.
- Configure category allocations.
- Add, edit, filter, paginate, and delete expenses.
- Analyze budget health, burn rate, projected spending, and potential shortfall.
- Validate positive amounts, category allocations, currency, and overspending rules.

### Activity and itinerary planning

- Create and manage activities.
- Search activities with filters and pagination.
- Schedule activities for a trip.
- Detect overlapping activities.
- Check activity costs against the trip budget.
- Optimize and review a trip itinerary.

### Trip collaboration

- Invite travellers by email.
- Assign Owner, Editor, and Viewer roles.
- Submit weighted member preferences.
- Vote once per activity.
- Resolve group consensus when at least 60% of members participate.
- Calculate fairness and satisfaction scores.
- Escalate tied decisions for human arbitration.
- Accept or decline invitations through notifications.

### Risk and readiness

- Store and manage trip risk assessments.
- Retrieve destination weather information.
- Track travel-readiness documents and tasks.

### Authentication

- Register and log in with JWT authentication.
- Protect authenticated API routes.
- Store the authentication token securely in the mobile app.

## Technology stack

### Backend

- .NET 8 / ASP.NET Core Web API
- Entity Framework Core 8
- PostgreSQL through Npgsql
- Supabase PostgreSQL
- JWT Bearer authentication
- BCrypt password hashing
- Swagger/OpenAPI
- SMTP email delivery for invitations

### Web

- React 19
- Vite
- React Router
- Axios
- React Hook Form
- Zod validation
- Tailwind CSS
- Lucide React icons
- Oxlint

### Mobile

- Flutter
- Dart 3.2 or newer
- Riverpod
- Dio
- GoRouter
- flutter_secure_storage
- flutter_dotenv
- Google Fonts

## Repository structure

```text
projectT/
├── README.md
└── TravelWise/
    ├── backend/
    │   └── backend/
    │       └── TravelWise.API/
    │           ├── Controllers/
    │           ├── Data/
    │           ├── DTOs/
    │           ├── Migrations/
    │           ├── Models/
    │           ├── Services/
    │           ├── Program.cs
    │           ├── appsettings.json
    │           └── TravelWise.API.csproj
    ├── frontend-web/
    │   ├── src/
    │   ├── package.json
    │   └── .env
    └── mobile/
        ├── lib/
        ├── pubspec.yaml
        └── .env
```

## Prerequisites

Install the following tools:

- Git
- .NET SDK 8
- Node.js and npm
- Flutter SDK
- Android Studio and an Android emulator, if running the Android app
- A Supabase project with PostgreSQL access

Verify installations:

```powershell
git --version
dotnet --version
node --version
npm --version
flutter --version
```

## Configuration

### Backend secrets

The backend requires a Supabase PostgreSQL connection string and JWT settings.
Do not commit database passwords, SMTP passwords, JWT signing keys, or other
credentials.

From the API directory, configure local user secrets:

```powershell
cd C:\Users\sheha\Desktop\projectT\TravelWise\backend\backend\TravelWise.API

dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=aws-0-ap-southeast-2.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.<project-ref>;Password=<database-password>;SSL Mode=Require;Trust Server Certificate=true"
dotnet user-secrets set "Jwt:Key" "<random-secret-at-least-32-characters>"
dotnet user-secrets set "Jwt:Issuer" "TravelWiseAPI"
dotnet user-secrets set "Jwt:Audience" "TravelWiseClients"
```

The application is configured to use Supabase PostgreSQL. The Session Pooler
hostname is recommended for local development because it is generally more
reliable than a direct database hostname.

For invitation email delivery, configure an SMTP provider. Gmail requires
two-step verification and an app password:

```powershell
dotnet user-secrets set "Email:Host" "smtp.gmail.com"
dotnet user-secrets set "Email:Port" "587"
dotnet user-secrets set "Email:EnableSsl" "true"
dotnet user-secrets set "Email:Username" "your-address@gmail.com"
dotnet user-secrets set "Email:Password" "<gmail-app-password>"
dotnet user-secrets set "Email:FromAddress" "your-address@gmail.com"
dotnet user-secrets set "Email:FromName" "TravelWise"
```

The frontend URL can be overridden when needed:

```powershell
dotnet user-secrets set "Frontend:BaseUrl" "http://localhost:5173"
```

### Web environment

Create `TravelWise/frontend-web/.env`:

```env
VITE_API_URL=http://localhost:5147/api
```

The web client defaults to this URL when `VITE_API_URL` is not provided.

### Mobile environment

The mobile app reads `TravelWise/mobile/.env`.

For Windows desktop, Chrome, or an iOS simulator:

```env
API_BASE_URL=http://localhost:5147/api
```

For an Android emulator:

```env
API_BASE_URL=http://10.0.2.2:5147/api
```

`10.0.2.2` is the Android emulator address for services running on the host
computer. A physical Android device must use the host computer's LAN IP, for
example `http://192.168.1.10:5147/api`, and the API must listen on an accessible
network interface.

## Running the project

Run the backend before either client.

### 1. Start the API

```powershell
cd C:\Users\sheha\Desktop\projectT\TravelWise\backend\backend\TravelWise.API
dotnet restore
dotnet run --launch-profile http
```

The API is available at:

- API: `http://localhost:5147`
- Swagger UI: `http://localhost:5147/swagger`
- Database health: `http://localhost:5147/api/health/database`

The HTTPS profile is also available:

```powershell
dotnet run --launch-profile https
```

### 2. Run the React web app

Open a second PowerShell terminal:

```powershell
cd C:\Users\sheha\Desktop\projectT\TravelWise\frontend-web
npm install
npm run dev
```

Open the URL printed by Vite, normally `http://localhost:5173`.

Useful web commands:

```powershell
npm run lint
npm run build
npm run preview
```

### 3. Run the Flutter app

Open a third PowerShell terminal:

```powershell
cd C:\Users\sheha\Desktop\projectT\TravelWise\mobile
flutter pub get
flutter devices
flutter run
```

Run on a specific target:

```powershell
flutter run -d chrome
flutter run -d windows
flutter run -d <android-device-id>
```

Start an Android emulator through Android Studio before running the Android
target. Ensure `mobile/.env` uses `10.0.2.2` for the emulator.

## Database migrations

The API uses Entity Framework Core migrations. After configuring the Supabase
connection string, apply migrations from the API directory:

```powershell
cd C:\Users\sheha\Desktop\projectT\TravelWise\backend\backend\TravelWise.API
dotnet ef database update
```

If the EF command is not installed:

```powershell
dotnet tool install --global dotnet-ef
```

After changing an entity or database mapping, create a migration:

```powershell
dotnet ef migrations add DescribeTheChange
dotnet ef database update
```

Never delete or reorder migrations that have already been applied to the shared
Supabase database without coordinating a rollback.

## API areas

The API uses controller-based routes under `/api`.

| Area | Main routes |
| --- | --- |
| Authentication | `/api/Auth/register`, `/api/Auth/login` |
| Trips | `/api/Trip` |
| Budgets | `/api/Budget`, `/api/Budgets/{tripId}/analyze-health` |
| Activities | `/api/Activity`, `/api/activities/search` |
| Schedules | `/api/trips/{tripId}/schedule` |
| Collaboration | `/api/trips/{tripId}/members`, `/preferences`, `/resolve-consensus` |
| Notifications | `/api/notifications` |
| Risk | `/api/Risk` |
| Readiness | `/api/Readiness` |
| Health | `/api/health/database` |

Use Swagger at `http://localhost:5147/swagger` for request and response
schemas. Most endpoints require a bearer token returned by login or registration.

## Typical workflow

1. Register a user or log in.
2. Create a trip from the Trips page or mobile app.
3. Select that trip on the Budget page and create its budget.
4. Add categories and expenses to the selected trip budget.
5. Add activities and schedule them for the same trip.
6. Invite other travellers from Collaboration.
7. Collect preferences and activity votes.
8. Resolve consensus after the required participation threshold is reached.
9. Review risk assessments and readiness tasks before travelling.

Trip data is persisted in Supabase. The web and mobile clients use the same API,
so changes made by one client are available to the others after refresh.

## Troubleshooting

### The API cannot connect to PostgreSQL

- Confirm the Supabase connection string is configured through user secrets.
- Prefer the Supabase Session Pooler hostname.
- Confirm the database password has not expired or been rotated.
- Check `http://localhost:5147/api/health/database`.
- Restart the API after changing secrets.

### The web app shows a network error

- Start the API on port `5147`.
- Confirm `VITE_API_URL` ends with `/api`.
- Confirm the browser is using the expected frontend URL.
- Check the browser developer console and API Swagger page.

### Android cannot reach the API

Use this mobile setting:

```env
API_BASE_URL=http://10.0.2.2:5147/api
```

Do not use `localhost` inside an Android emulator; it points to the emulator
itself rather than the development computer.

### Invitation email cannot be delivered

- Configure all `Email:*` user secrets.
- Use a Gmail app password instead of the normal Gmail password.
- Confirm port `587` and SSL are enabled.
- Restart the API after changing SMTP secrets.
- Check that the SMTP provider allows the configured account to send mail.

### Database tables are missing

Run:

```powershell
dotnet ef database update
```

Ensure the command is executed from the directory containing
`TravelWise.API.csproj` and that it uses the intended Supabase connection.

## Security notes

- Never commit real passwords, API keys, JWT keys, SMTP credentials, or Supabase
  secrets.
- Use `dotnet user-secrets` or environment variables for local secrets.
- Rotate credentials immediately if they are exposed in source control, logs, or
  chat.
- Do not use production credentials for local development.
- Keep JWT signing keys at least 32 characters long and use a cryptographically
  random value.

## Validation

Backend build:

```powershell
cd C:\Users\sheha\Desktop\projectT\TravelWise\backend\backend\TravelWise.API
dotnet build
```

Web lint and production build:

```powershell
cd C:\Users\sheha\Desktop\projectT\TravelWise\frontend-web
npm run lint
npm run build
```

Flutter analysis and tests:

```powershell
cd C:\Users\sheha\Desktop\projectT\TravelWise\mobile
flutter analyze
flutter test
```

## License

This project was created as a TravelWise software engineering assignment.
