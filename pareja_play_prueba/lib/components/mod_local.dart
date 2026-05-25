import 'package:flutter/material.dart';
import 'package:pareja_play_prueba/screens/seleccionar_preguntas_local.dart';

class ModLocal extends StatefulWidget {
  const ModLocal({super.key});

  @override
  State<ModLocal> createState() => _ModLocalState();
}

class _ModLocalState extends State<ModLocal> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 100.0,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: SizedBox(
            height: 60,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeleccionarPreguntasLocal(),
                  ),
                );
              },
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: Text(
                'Modo Local',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
