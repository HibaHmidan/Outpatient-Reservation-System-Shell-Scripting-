# Outpatient Reservation System (Shell Scripting)

A **terminal-based outpatient reservation system** developed using **Bash shell scripting**.
The system allows patients to book appointments and admins to manage doctors and schedules using simple text files as a database.

---

## Features

### Patient Features

* Register as a new patient
* Book appointments with available doctors
* View personal appointment history
* Cancel existing appointments

### Admin Features

* Add new doctors
* Update doctor schedules
* View doctor appointment schedules
* Generate daily reports
* Backup system data

---

## System Structure

The system stores data in simple **pipe-delimited text files**:

```
doctors.txt
patients.txt
appointments.txt
```

### doctors.txt

Format:

```
DoctorID|Name|Specialty|AvailableDates|StartTime|EndTime
```

Example:

```
D001|Dr. Mona Youssef|Dermatology|Sun,Mon,Wed|09:00|15:00
```

### patients.txt

Format:

```
PatientID|Name|Phone
```

Example:

```
P002|Ali Ahmed|01087654321
```

### appointments.txt

Format:

```
AppointmentID|PatientID|DoctorID|Date|Time|Status
```

Example:

```
A003|P002|D001|2024-08-10|09:30|Confirmed
```

---

## How the System Works

When the program starts, the user chooses a role:

1. **Patient**
2. **Admin**

Each role provides different menu options and services.

The system checks:

* Valid input formats
* Doctor availability
* Duplicate entries
* Appointment conflicts

This prevents double bookings and invalid data.

## Key Concepts Demonstrated

* Menu-driven shell applications
* File processing in Bash
* Data validation
* Conflict detection for bookings
* Role-based access control

---

## Authors

* Hiba Hmidan
* Celine Nasser Elddin

Birzeit University
