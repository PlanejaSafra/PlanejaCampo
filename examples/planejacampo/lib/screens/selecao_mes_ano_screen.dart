import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/l10n/l10n.dart';

class SelecaoMesAnoScreen extends StatefulWidget {
  final DateTime initialDate;

  const SelecaoMesAnoScreen({Key? key, required this.initialDate}) : super(key: key);

  @override
  _SelecaoMesAnoScreenState createState() => _SelecaoMesAnoScreenState();
}

class _SelecaoMesAnoScreenState extends State<SelecaoMesAnoScreen> {
  late DateTime _selectedDate;
  late int _year;
  final List<String> _months = List.generate(12, (index) => DateFormat('MMMM').format(DateTime(2023, index + 1)));

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _year = _selectedDate.year;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).selectMonth),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => setState(() => _year--),
              ),
              Text('$_year', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () => setState(() => _year++),
              ),
            ],
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              return ElevatedButton(
                child: Text(_months[index]),
                onPressed: () {
                  _selectedDate = DateTime(_year, index + 1);
                  Navigator.of(context).pop(_selectedDate);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}