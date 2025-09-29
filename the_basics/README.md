# Unbound Sharelife Loan Management System

## Resources:
- Installing Flutter: https://youtu.be/1KidD72q87s?si=KqQ_V8afImhx6V-8
- Download Android Studio: https://youtu.be/8gc5z3aKc6k?si=zPzpXwIx48255TdD
- Web app development using Flutter: https://youtu.be/UOTwRXAh6VY?si=HxJeA8xFYtjh52k8

## How to Run Project Files:
1. Open a Powershell terminal to 'the_basics' dir
2. Run the program using this command:
    `flutter run -d chrome`

## Running Individual Files (for testing)
1. Add this at the end of very end of the file:
    `void main() {
        runApp(const MaterialApp(home: EncoderDashb()));
    }`
2. Run the file using this command. Change the dir as needed.
    `flutter run -t lib/encoder_dashb.dart`