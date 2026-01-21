import 'package:flutter/material.dart';

class BigCalculatorKeypad extends StatelessWidget {
  final Function(String) onDigitPress;
  final VoidCallback onClear;
  final VoidCallback onAdd;

  const BigCalculatorKeypad({
    super.key,
    required this.onDigitPress,
    required this.onClear,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[100],
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildButton('7'),
                _buildButton('8'),
                _buildButton('9'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildButton('4'),
                _buildButton('5'),
                _buildButton('6'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildButton('1'),
                _buildButton('2'),
                _buildButton('3'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildButton('C',
                    color: Colors.red[100], textColor: Colors.red),
                _buildButton('0'),
                _buildButton('.', label: ','),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Maximum height
                        minimumSize: const Size.fromHeight(double.infinity),
                      ),
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 32),
                      label: const Text(
                        'ADICIONAR PESO',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String value,
      {String? label, Color? color, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (value == 'C') {
                onClear();
              } else {
                onDigitPress(value);
              }
            },
            child: Center(
              child: Text(
                label ?? value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
