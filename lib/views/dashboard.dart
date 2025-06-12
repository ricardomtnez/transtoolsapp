import 'package:flutter/material.dart';
class Dashboard extends StatelessWidget {
  final String nombre;
  final String departamento;
  final String email;

  const Dashboard({
    super.key,
    required this.nombre,
    required this.departamento,
    required this.email,
  });
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.fromARGB(255, 233, 227, 227), Color.fromARGB(255, 212, 206, 206)], // efecto gris degradado
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            const SizedBox(height: 60), // separación desde arriba
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
            nombre,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Cotizador'),
              onTap: () {
                Navigator.pushNamed(context, '/seccion1', arguments: { 
                  'nombre': nombre,'departamento': departamento,'email': email,
  },
);
                // Navegar o hacer acción
              },
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 35),
          child: Text(
            'Versión 1.0',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    ),
  ),
),

      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      backgroundColor: Colors.blue[800],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  
                  "Bienvenido",
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Text(
            nombre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,),
                  ),
                const SizedBox(height: 10),
                Container(
                padding: const EdgeInsets.all(10),
                 child: Column(
                children: [
                Image.asset(
               'assets/transtools_logo_white.png',
                width: 180,
                fit: BoxFit.contain,
           ),
        ],
            ),
                ),  
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text("Cotizaciones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text("0", style: TextStyle(fontSize: 30)),
                      const SizedBox(height: 15),
                      ElevatedButton(
                      onPressed: () {
                      Navigator.pushNamed(context, '/seccion1',arguments: {
                        'nombre': nombre, 'departamento': departamento, 'email': email,
                      },
                      );
                      },
                      style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      minimumSize: const Size(100, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Nueva Cotización", style: TextStyle(color: Colors.white)),
          ),

                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          minimumSize: const Size(163, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                        ("Borradores"),
                        style: TextStyle(color: Colors.white),
                      ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Cotizaciones Recientes", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(),
                          1: FlexColumnWidth(),
                          2: FlexColumnWidth(),
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(width: 0.5, color: Colors.grey),
                        ),
                        children: const [
                          TableRow(children: [
                            Text("Nombre", textAlign: TextAlign.center),
                            Text("Cliente", textAlign: TextAlign.center),
                            Text("Fecha", textAlign: TextAlign.center),
                          ]),
                          TableRow(children: [
                            Text(""),
                            Text(""),
                            Text(""),
                          ]),
                          TableRow(children: [
                            Text(""),
                            Text(""),
                            Text(""),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          ("Ver Más"),
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

