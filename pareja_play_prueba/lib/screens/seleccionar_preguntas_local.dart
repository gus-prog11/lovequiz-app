import 'package:flutter/material.dart';
import 'package:pareja_play_prueba/components/type_of_questions.dart';
import 'package:pareja_play_prueba/screens/preguntas_screen.dart';

class SeleccionarPreguntasLocal extends StatefulWidget {
  const SeleccionarPreguntasLocal({super.key});

  @override
  State<SeleccionarPreguntasLocal> createState() =>
      _SeleccionarPreguntasLocalState();
}

class _SeleccionarPreguntasLocalState extends State<SeleccionarPreguntasLocal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(197, 255, 0, 208),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 100,
                child: Text(
                  'Selecciona los tipos de preguntas que quieras',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    height: 4,
                  ),
                ),
              ),
            ),
            // take remaining space for question types
            Expanded(child: TypeOfQuestions()),
            // continue button fixed at bottom
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 60,
              ),
              child: SizedBox(
                height: 60,
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PreguntasScreen(),
                      ),
                    );
                  },

                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
