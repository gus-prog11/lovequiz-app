import 'package:flutter/material.dart';

class TypeOfQuestions extends StatefulWidget {
  const TypeOfQuestions({super.key});

  @override
  State<TypeOfQuestions> createState() => _TypeOfQuestionsState();
}

class _TypeOfQuestionsState extends State<TypeOfQuestions> {
  bool funnyIsSelected = false;
  bool sadIsSelected = false;
  bool unconfortableIsSelected = false;
  bool hotIsSelected = false;
  bool loveIsSelected = false;
  bool locasIsSelected = false;
  bool personalizadasIsSelected = false;
  bool retosIsSelected = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Divertidas
            SizedBox(
              width: 200,
              height: 80,

              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 8,
                  bottom: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      funnyIsSelected = !funnyIsSelected;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: funnyIsSelected ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Divertidas',

                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              // Tristes
              width: 200,
              height: 80,

              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  top: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      sadIsSelected = !sadIsSelected;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: sadIsSelected ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Tristes',

                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Incomodas
            SizedBox(
              width: 200,
              height: 80,

              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 8,
                  bottom: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      unconfortableIsSelected = !unconfortableIsSelected;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: unconfortableIsSelected
                          ? Colors.blue
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Incomodas',

                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Calientes
            SizedBox(
              width: 200,
              height: 80,

              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  top: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      hotIsSelected = !hotIsSelected;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: hotIsSelected ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Calientes',

                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Amorosas
            SizedBox(
              width: 200,
              height: 80,

              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 8,
                  bottom: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      loveIsSelected = !loveIsSelected;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: loveIsSelected ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Amorosas',

                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Locas
            SizedBox(
              width: 200,
              height: 80,

              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  top: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      locasIsSelected = !locasIsSelected;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: locasIsSelected ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Locas',

                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Personalizadas
            SizedBox(
              width: 200,
              height: 80,

              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 8,
                  bottom: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      personalizadasIsSelected = !personalizadasIsSelected;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: personalizadasIsSelected
                          ? Colors.blue
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Personalizadas',

                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Retos
            SizedBox(
              width: 200,
              height: 80,

              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  top: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      retosIsSelected = !retosIsSelected;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: retosIsSelected ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Retos',

                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
