#!/bin/bash

# Hiba Hmidan 1230454
#Celine Nasser Elddin 1230867
#section 1

# add doctor function 
add_doctor(){
  echo "To add a new doctor please enter the following: "
  read -p "Enter doctor name: " name
  read -p "Enter specialty: " specialty
  read -p "Enter working days: " working_days
read -p "Enter start time(hh:mm): " start
while ! is_valid_time_format "$start"; do
  read -p "Enter start time(hh:mm): " start
done
read -p "Enter end time(hh:mm): " end
while ! is_valid_time_format "$end"; do
  read -p "Enter end time(hh:mm): " end
done

#check if doctor is already added
if  grep "|$name|$specialty" "doctors.txt" > /dev/null
  then
   echo  "Doctor already added!"
  else
doctorID=$(generate_id "doctors.txt" "D")
echo 
echo "$doctorID|$name|$specialty|$working_days|$start|$end" >> doctors.txt  #save info in this format
echo "$doctorID|$name|$specialty|$working_days|$start|$end" >> doctorsBackup.txt  #save info in this format
echo "Doctor $name added successfully with ID $doctorID"
  fi
}

ViewSchedule(){
# check file exist ant not empty
if [ ! -f doctors.txt ] || [ ! -s doctors.txt ];then
    echo "no doctors currently available "
    return
 fi
echo "==Available Doctors=="
cut -d'|' -f1,2 doctors.txt
read -p "Enter Doctor ID to view schedule: " ID
line=$(grep "^$ID" doctors.txt)
if [ -z "$line" ]; then #if string is null
echo "Doctor not found"
return
fi
# check for listed appointments
if ! grep "|$ID|" appointments.txt > /dev/null; then
  echo "no appointments for this doctor!" 
  return
fi

dateToday=$(date +%F) #this is to display date as yyyy-mm-dd (we found it using date --help)
echo -n> upcomingApp.txt
echo 
echo "==Appointments for $ID=="
#look through all appointments
grep "$ID" appointments.txt | while read -r line; do
patientID=$(echo "$line" | cut -d'|' -f2)
date=$(echo "$line" | cut -d'|' -f4)
timee=$(echo "$line" | cut -d'|' -f5)
status=$(echo "$line" | cut -d'|' -f6)

#get patient name
patient_line=$(grep "$patientID" patients.txt)
pname=$(echo "$patient_line" |cut -d'|' -f2)

# check if appointment is today or in the future
if [[ "$date" > "$dateToday" ]] || [[ "$date" == "$dateToday" ]]; then
       echo "date: $date, Time: $timee, Patient name: $pname, status: $status" >> upcomingApp.txt
fi
done
if [ ! -s upcomingApp.txt ]; then
    echo "no appointments currently available "
else
 sort upcomingApp.txt 
fi
}

update_specialty(){
  newSpecialty="$1"
  DID="$2"
  appointments=$(grep "|$DID|" appointments.txt )
  for line in $appointments ; do
    AID=$(echo $line | cut -d'|' -f1)
    Date=$(echo $line | cut -d'|' -f4)
    Time=$(echo $line | cut -d'|' -f5)
    status=$(echo $line | cut -d'|' -f6)

    timeNow=$(date +%H:%M)
    dateToday=$(date +%F) #this is to display date as yyyy-mm-dd (we found it using date --help)
  if [[ "$status" == "Confirmed" ]];then
    if [[ "$Date" > "$dateToday" ]] ; then
       echo "Cancelled appointment with Id $AID becuse doctor changed specialty" 
       sed -i "/^$AID|/s/Confirmed/Cancelled/" appointments.txt
    elif [[ "$Date" < "$dateToday" ]]; then
       :
    elif [[ "$Time " > "$timeNow" ]]; then #if the appointment is today but time is not now yet
      echo "Cancelled appointment with Id $AID becuse doctor changed specialty" 
      sed -i "/^$AID|/s/Confirmed/Cancelled/" appointments.txt
    fi
  fi
   done
}


UpdateSchedule(){
# check file exist and not empty
if [ ! -f doctors.txt ] || [ ! -s doctors.txt ];then
    echo "no doctors currently available "
    return
 fi

echo "==Available Doctors=="
cut -d'|' -f1,2 doctors.txt
echo 
read -p "Enter Doctor ID to update: " ID
line=$(grep "^$ID" doctors.txt)
if [ -z "$line" ]; then  #if string is null
echo "Doctor not found"
return
fi

name=$(echo "$line" | cut -d'|' -f2)
oldSpeciality=$(echo "$line" | cut -d'|' -f3)
days=$(echo "$line" | cut -d'|' -f4)
start=$(echo "$line" | cut -d'|' -f5)
end=$(echo "$line" | cut -d'|' -f6)
speciality="$oldSpeciality"
echo 
echo " ==Current info=="
echo " Name: $name, Speciality: $speciality, Days: $days, Working hours: $start - $end "

while true; do
echo 
echo "What would you like to update:"
echo "1. speciality"
echo "2. Working days"
echo "3. Start time"
echo "4. End time"
echo "5. Save and exit"
echo "6. Cancel"
read -p "choice: " choice

case $choice in
1) read -p "Enter new Speciality: " speciality 
echo "$speciality" ;;
2)
echo "Current working days : $days"
read -p "Enter new Working days to add (comma sperated): " newdays
#seperate each dayin line to sort and remove duplicates if found
days=$(echo "$days,$newdays" | tr ',' '\n' | sort -u |paste -sd, -)
echo "Updated days are: $days "
;;
3)
 while true; do
echo "====="
  read -p "Enter new start time (hh:mm) or enter 'cancel' to skip: " newstart
echo "====="
if [[ "$newstart" == "cancel" ]]; then
echo "start time change canceled"
break
fi
if ! is_valid_time_format "$newstart"; then #check time format
continue
fi
#check if new time is earlier
time_comparsion "$start" "$newstart"
result=$?
if [ "$result" -eq 0 ];then #true
start="$newstart"
echo "start time updated to $start"
break
else
echo "Start time must be earlier than current start time ($start)."
fi
done
;;

4)
 while true; do
echo "====="
  read -p "Enter new end time (hh:mm) or enter 'cancel' to skip: " newend
echo "====="
if [[ "$newend" == "cancel" ]]; then
echo "end time change canceled"
break
fi
if ! is_valid_time_format "$newend"; then #check time format
continue
fi
# check if new end time is later
time_comparsion "$end" "$newend"
result=$?
if [ "$result" -eq 1 ]; then #true
end="$newend"
echo "End time updated to $end"
break
else
 echo "end time must be later than the current end time: $end"
fi
done
;;

5) #update file
if [ "$speciality" != "$oldSpeciality" ]; then
update_specialty "$speciality" "$ID"
sed -i "/^$ID|/s/$oldSpeciality/$speciality/" doctors.txt
echo "Specialty updated!"
fi
newline="$ID|$name|$speciality|$days|$start|$end"
echo "new info : $newline"
#replace the line that starts with ID to the new updated line
sed -i "s/^$ID.*/$newline/" doctors.txt
sed -i "s/^$ID.*/$newline/" doctorsBackup.txt
echo "Doctor schedule updated successfully"
break
;;
6)
echo "Update cancelled"
break
;;
*) echo "Invalid choice, try again!";;
esac
done
}


time_comparsion(){
oldTime="$1"
newTime="$2" #time we want to update to

# separate the time into hours and minutes
oldHour=$(echo "$oldTime" | cut -d':' -f1)
newHour=$(echo "$newTime" | cut -d':' -f1)

oldMin=$(echo "$oldTime" | cut -d':' -f2)
newMin=$(echo "$newTime" | cut -d':' -f2)
# 0:old time is later than new time
# 1:old time is earlier then new time
# 2:times are equal
if [ "$oldHour" -lt "$newHour" ]; then
return 1
elif [ "$oldHour" -gt "$newHour" ]; then
return 0
else #hours are equal, check minutes
if [ "$oldMin" -lt "$newMin" ]; then
return 1
elif [ "$oldMin" -gt "$newMin" ]; then
return 0
else
return 2 #times are equal
fi
fi
}

#function that generates unique ID
generate_id(){
file="$1" #the file that we want to generate for
letter="$2" # D for doctor, P for patient, A for appointment
if [ ! -f "$file" ] 
then
echo "Creating File..."
echo "${letter}001"
else
maxID=$(cut -d'|' -f1 "$file" | sed "s/^$letter//" | sed 's/^0*//' | sort -n | tail -n 1 ) # we find the max id that is already in the file so we can add 1 to it
if [[ -z "$maxID" ]]; then
 echo "${letter}001"
 return
fi
newID=$((maxID + 1)) #increment the max ID by 1
printf "%s%03d" "$letter" "$newID"
fi
}

#A function that registers a new patient
register_patient(){
  echo "To register a new patient please enter the following: "
  read -p "Enter name: " name
  read -p "Enter phone: " phone

  while [[ ! "$phone" =~ ^[0-9]{11}$ ]] # ensure that the phone number is 11 digits
  do
    echo "Phone number must be 11 numeric digits! "
    read -p "Please enter phone again or enter cancel: " phone
    if [ $phone = "cancel" ]
    then
      echo "Exiting add process."
      return 1
    fi
  done

  if  grep "|$name|$phone" patients.txt > /dev/null # avoid registering the same patient again
  then
   echo "Duplicate Patient: patient with same name and phone already registered!"
  else
   ID=$(generate_id "patients.txt" "P")
   echo "$ID|$name|$phone" >> patients.txt
   echo "$ID|$name|$phone" >> patientsBackup.txt
   echo "Patient added successfully!"
  fi
}

is_valid_date() {
  dateToday=$(date +%F)
    if [[ $1 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] # check that it is on the form yyyy-mm-dd
    then
       year=$(echo "$1" | cut -d- -f1)
       month=$(echo "$1" | cut -d- -f2)
       day=$(echo "$1" | cut -d- -f3)

if [ "$month" -ge 1 ] && [ "$month" -le 12 ] && [ "$day" -ge 1 ] && [ "$day" -le 31 ]; then # check that months and days are within their range
          if  [[ "$1" < "$dateToday" ]];then # check that only new dates are entered
                 echo "The date you entered should not be an old date! "
                return 1
          else
                 return 0
           fi
        else
            return 1
        fi
    else
        return 1
    fi
}

is_valid_time_format(){
 Time="$1"
 if [[ ! "$Time" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then # check that the time is on the format hh:mm
   echo "Time format incorrect, it should be hh:mm"
   return 1
 fi
  hour=$(echo "$Time" | cut -d: -f1)
  minute=$(echo "$Time" | cut -d: -f2)
   if [ "$hour" -ge 0 ] && [ "$hour" -le 23 ] && [ "$minute" -ge 0 ] && [ "$minute" -le 59 ]; then #check that entered hours and minutes are within their range
     return 0
   else
     echo "Incorrect Time Format"
     return 1
   fi
}

book_appointment(){
  echo
  read -p "To boo an appintmnet please enter your ID: " PID
  if ! grep "^$PID|" patients.txt > /dev/null ; then # First, we find the patient that wants to book an appointment
   echo "patient not found !"
   return
  else
    name=`grep "^$PID" patients.txt | cut -d'|' -f2`
  fi
  
 if [ ! -f doctors.txt ] || [ ! -s doctors.txt ];then 
    echo "no doctors currently available "
    return
 fi
 
  echo -e "\nWelcome $name, the following are the doctors specialties available: " # ask the user for the specialty
  cut -d'|' -f3 doctors.txt 
  echo "Please neter your selection"
  read specialty
  if ! grep -i "$specialty" doctors.txt > /dev/null; then 
   echo "Entered Specialty is not currently available !"
   return
  else
   echo -e "\nThe following are the available doctors of your chosen specialty:"
   
   
   availableDoctors=$(grep "$specialty" doctors.txt) # find doctors with the entered specialty
  while read -r line ;do
    DID=$(echo $line | cut -d'|' -f1)
    Dname=$(echo $line | cut -d'|' -f2)
    Days=$(echo $line | cut -d'|' -f4)
    start=$(echo $line | cut -d'|' -f5)
    end=$(echo $line | cut -d'|' -f6)
    echo "Doctor ID: $DID, Doctor name: $Dname,Available Days: $Days. start time: $start, end time: $end." 
   done <<< "$availableDoctors"
   
   echo
   read -p "Enter doctor ID from list above:  " DID # ask the user to enter doctor ID
    if ! grep "^$DID" doctors.txt| grep "$specialty" > /dev/null ; then
     echo "chosen doctor not found!"
     return
    fi
 fi

     read -p "Enter desired date in the format YYYY-MM-DD: " date
     while ! is_valid_date "$date" #ensure that the user enters a valid date
      do
        echo "Please enter a valid date or enter cancel to cancel the booking proccess: "
        read date
        if [ "$date" = "cancel" ]
        then
          echo "Exiting add process."
          return
          fi
       done

     day=$(date -d "$date" '+%a') #This is to know the date is which day (Sun, Mon..)
     
     while ! grep "^$DID" doctors.txt| cut -d'|' -f4| grep "$day" > /dev/null
     do
       day=$(date -d "$date" '+%a')
       echo "The Doctor is not available on the day of the entered day wich is $day "
       read -p "Enter desired date in the format YYYY-MM-DD: " date
     while ! is_valid_date "$date" #ensure that the user enters a valid date
      do
        echo "Please enter a valid date or enter cancel to cancel the booking proccess: "
        read date
        if [ "$date" = "cancel" ]
        then
          echo "Exiting add process."
          return
          fi
       done
       day=$(date -d "$date" '+%a')
     done
     
     #if ! grep "^$DID" doctors.txt| cut -d'|' -f4| grep "$day" > /dev/null ; then #make sure that user-entered date corresponds to an available doctor's working day
      #echo "The Doctor is not available on the day of the entered day wich is $day "
      #return
     #fi
     
     read -p "Please enter your desired Time of the appointment: " Time
     while !  is_valid_time_format "$Time" #make sure that the entered time is valid
      do
        echo "Please enter a valid time or enter cancel to cancel the booking proccess: "
        read Time
        if [ "$Time" = "cancel" ]
        then
          echo "Exiting add process."
          return
          fi
       done
       
     doctorStart=$(grep "^$DID" doctors.txt| cut -d'|' -f5)
     doctorEnd=$(grep "^$DID" doctors.txt| cut -d'|' -f6)
            
   if [[ "$Time" > "$doctorStart" && "$Time" < "$doctorEnd" ]]; then  #this is to make sure that entered time is within the dotcor's working hours and not booked before by doctor or user
     if  grep "$DID" appointments.txt|grep "$date" |cut -d'|' -f5 | grep "$Time" > /dev/null ; then
       echo "This appointment is not available, it has been booked before"
     elif grep "|$PID|" appointments.txt | grep "|$date|" | grep  "|$Time|" > /dev/null ; then 
       echo "The patient has another appointment at this time !"
     else
       read -p "Do you want to confirm your booking (yes/no): " status
       if [ "$status" = "no" ] ;then
         echo "exiting booking proccess"
         return
       else
         status="Confirmed"
         AID=$(generate_id "appointments.txt" "A")
         echo "$AID|$PID|$DID|$date|$Time|$status" >> appointments.txt
         echo "$AID|$PID|$DID|$date|$Time|$status" >> appointmentsBackup.txt
         echo "Booked appointment successfully"
         fi
       fi
      else
      echo "Entered time is not within the range of the doctor's time "
     fi

}

view_appointments(){
   if [ ! -f appointments.txt ]; then  # check if the file exists
    echo "appointments file not found! "
    return
   fi

  dateToday=$(date +%F) #this is to display date as yyyy-mm-dd (we found it using date --help)

  read -p "Please enter your ID to view your appointments: " PID
  if ! grep "^$PID|" patients.txt > /dev/null ; then
   echo "patient not found !"
   return
  else
    name=`grep "^$PID" patients.txt | cut -d'|' -f2`
  fi

  echo -n > upcomingApp.txt #empty multiple files that will store upcoming, previous, and cancelled appointments
  echo -n > previousApp.txt
  echo -n > cancelled.txt

   myAppointments=$(grep "|$PID|" appointments.txt) #find the patients appointments and sort each based on its date or status 
  for line in $myAppointments ; do
    AID=$(echo $line | cut -d'|' -f1)
    DID=$(echo $line | cut -d'|' -f3)
    Dname=$(grep "^$DID" doctors.txt|cut -d'|' -f2)
    Date=$(echo $line | cut -d'|' -f4)
    Time=$(echo $line | cut -d'|' -f5)
    status=$(echo $line | cut -d'|' -f6)

    timeNow=$(date +%H:%M)
    if [[ "$status" =~ "Cancelled" ]];then
       echo "appointment ID: $AID, Doctor name: $Dname, Date= $Date, Time= $Time, status= $status." >> cancelled.txt
    elif [[ "$Date" > "$dateToday" ]] ; then
       echo "appointment ID: $AID, Doctor name: $Dname, Date= $Date, Time= $Time, status= $status." >> upcomingApp.txt
    elif [[ "$Date" < "$dateToday" ]]; then
       echo "appointment ID: $AID, Doctor name: $Dname, Date= $Date, Time= $Time, status= $status." >> previousApp.txt
    elif [[ "$Time " > "$timeNow" ]]; then
       echo "appointment ID: $AID, Doctor name: $Dname, Date= $Date, Time= $Time, status= $status." >> upcomingApp.txt
    else
        echo "appointment ID: $AID, Doctor name: $Dname, Date= $Date, Time= $Time, status= $status." >> previousApp.txt
   fi
   done
  if [ -s  previousApp.txt ]; then
    echo -e  "\n$name's previous appointments are: "
    cat previousApp.txt
  else
    echo -e "\nno previous appointments"
  fi

  if [ -s  upcomingApp.txt ]; then
    echo -e "\n$name's upcoming appointments are: "
    cat upcomingApp.txt
  else
    echo -e "\nno previous appointments"
  fi

  if [ -s cancelled.txt ]; then
    echo -e "\n$name's cancelled appointments were: "
    cat cancelled.txt
  else
    echo -e "\nno cancelled appointments"
  fi

}

cancel_appointment(){
if [ ! -f appointments.txt ]; then
    echo "appointments file not found! "
    return
   fi

  dateToday=$(date +%F) #this is to display date as yyyy-mm-dd (we found it using date --help)

  read -p "Please enter your ID to view your appointments: " PID
  if ! grep "^$PID|" patients.txt > /dev/null ; then
   echo "patient not found !"
   return
  else
    name=`grep "^$PID" patients.txt | cut -d'|' -f2`
  fi

  echo -n > upcomingApp.txt

  myAppointments=$(grep "|$PID|" appointments.txt) #find the patients upcoming appointments to display them and ask the user to cancel one of them
  for line in $myAppointments ; do
    AID=$(echo $line | cut -d'|' -f1)
    DID=$(echo $line | cut -d'|' -f3)
    Dname=$(grep "^$DID" doctors.txt|cut -d'|' -f2)
    Date=$(echo $line | cut -d'|' -f4)
    Time=$(echo $line | cut -d'|' -f5)
    status=$(echo $line | cut -d'|' -f6)

    timeNow=$(date +%H:%M)
   if [[ "$status" != "Cancelled" ]];then
    if [[ "$Date" > "$dateToday" ]] ; then
       echo "appointment ID: $AID, Doctor name: $Dname, Date: $Date, Time: $Time, status: $status." >> upcomingApp.txt
    elif [[ "$Date" == "$dateToday" ]] && [[ "$Time " > "$timeNow" ]] ; then
       echo "appointment ID: $AID, Doctor name: $Dname, Date: $Date, Time: $Time, status: $status." >> upcomingApp.txt
    fi
   fi
   done

  if [ ! -s  upcomingApp.txt ]; then
    echo "No upcoming appointments "
    return 
  fi
  
  echo -e "\n$name's upcoming appointments are: "
  cat upcomingApp.txt
  read -p "Please enter appointment ID from above to cancel: " AID
  
if ! grep "$AID" upcomingApp.txt > /dev/null; then
   echo "appoinment not from list above"
else
  sed -i "/^$AID|/s/Confirmed/Cancelled/" appointments.txt
  sed -i "/^$AID|/s/Confirmed/Cancelled/" appointmentsBackup.txt
  echo "Appointment Cancelled Successfully!"
 fi
}

# this menu displays different patient services
patient_menu(){
while true; do
   printf "\n\n"
   echo "   Welcome to Our Patient Service Menu   "
   echo "Please select a service:"
   echo "1. Register a New Patient"
   echo "2. Book an Appointment"
   echo "3. View your Appoinments"
   echo "4. Cancel an Appoinment"
   echo "5. Return Back to Main Menu"

   read -p "Enter selection [1-5]: " selection

 case "$selection" in
 1)register_patient;;
 2)book_appointment;;
 3)view_appointments;;
 4)cancel_appointment ;;
 5)echo "Returning to Main Menu !"
   main_menu ;;
 "") echo "Cancelled" ;;
 *) echo "Invalid choice" ;;
 esac
done

}

admin_menu(){
while true 
do
echo -e "\nAdmin menu"
echo "1. Add new Doctor"
echo "2. Update Doctor's schedule"
echo "3. View Doctor's schedule"
echo "4. Go back to main menu"
read -p "choose an option: " choice

case $choice in 
1)add_doctor;;
2)UpdateSchedule;;
3)ViewSchedule;;
4)break;;
*)echo "Invalid choice";;
esac
done
}



#function that displays main menu
main_menu(){
while true; do
  printf "\n\n"
   echo "   Welcome to Our Outpatient Reservation System   "
   echo "Please select your rule:"
   echo "1. Patient"
   echo "2. Admin"
   echo "3. Exit"

   read -p "Enter selection [1-3]: " selection

 case "$selection" in
 1)patient_menu ;;
 2)admin_menu ;;
 3)echo "Exiting the system, Goodbye!"
    exit 0 ;;
 "") echo "Cancelled" ;;
 *) echo "Invalid choice" ;;
 esac
done
}

#run the main menu
main_menu

#end of script
