import 'package:flutter/material.dart';

class TextInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  const TextInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = "",
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}

class NumberInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  const NumberInputField({
    super.key, 
    required this.label, 
    required this.controller, 
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}

class DateInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const DateInputField({
    super.key, 
    required this.label, 
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: "MM-DD-YYYY",
        suffixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          // Format as MM-DD-YYYY to match Figma
          String month = pickedDate.month.toString().padLeft(2, '0');
          String day = pickedDate.day.toString().padLeft(2, '0');
          String year = pickedDate.year.toString();
          controller.text = "$month-$day-$year";
        }
      },
    );
  }
}

class DateTimeInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const DateTimeInputField({
    super.key, 
    required this.label, 
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: "MM-DD-YYYY HH:MM",
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      onTap: () async {
        // First pick date
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        
        if (pickedDate != null) {
          // Then pick time
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          
          if (pickedTime != null) {
            // Combine date and time
            final dateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            
            // Format as MM-DD-YYYY HH:MM
            String month = dateTime.month.toString().padLeft(2, '0');
            String day = dateTime.day.toString().padLeft(2, '0');
            String year = dateTime.year.toString();
            String hour = dateTime.hour.toString().padLeft(2, '0');
            String minute = dateTime.minute.toString().padLeft(2, '0');
            controller.text = "$month-$day-$year $hour:$minute";
          }
        }
      },
    );
  }
}

class DropdownInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final List<String> items;
  final String? value;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;

  const DropdownInputField({
    super.key,
    required this.label,
    this.controller,
    required this.items,
    this.value,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: controller != null
          ? (controller!.text.isNotEmpty ? controller!.text : null)
          : value, // <-- use parent's state if controller is null
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: (value) {
        if (controller != null) {
          controller!.text = value ?? '';
        }
        onChanged?.call(value); // <-- always call this so parent updates
      },
      validator: validator,
    );
  }
}

class DropdownNonInputField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?)? onChanged;

  const DropdownNonInputField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class FileUploadField extends StatelessWidget {
  final String label;
  final String hint;
  final String? fileName;
  final VoidCallback onTap;

  const FileUploadField({
    super.key,
    required this.label,
    required this.hint,
    this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                SizedBox(width: 12),
                Icon(Icons.upload_file, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName ?? hint,
                    style: TextStyle(
                      color: fileName != null ? Colors.black : Colors.grey[600],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}