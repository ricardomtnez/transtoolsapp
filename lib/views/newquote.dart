import 'package:flutter/material.dart';

class NewQuote extends StatelessWidget {
  const NewQuote({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF53A9D1),
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
            const Text(
              'Ing. Ricardo Martinez',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Cotizador'),
              onTap: () {
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
        title: const Text('Nueva cotización'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionTitle('Información del Cliente'),
            Row(
              children: [
                Expanded(child: _buildInput('Nombre')),
                const SizedBox(width: 10),
                Expanded(child: _buildInput('Empresa')),
              ],
            ),
            _buildInput('Correo Electrónico'),
            _buildInput('Teléfono'),
            const SizedBox(height: 16),

            _buildSectionTitle('Fecha'),
            _buildInput('Ingrese la fecha'),
            const SizedBox(height: 16),

            _buildSectionTitle('Producto'),
            _buildDropdown(['Producto A', 'Producto B']),
            const SizedBox(height: 16),

            _buildSectionTitle('Tipo de Producto'),
            _buildDropdown(['Tipo 1', 'Tipo 2']),
            const SizedBox(height: 16),

            _buildSectionTitle('Documentos de Apoyo'),
            ElevatedButton(
              onPressed: () {
                // lógica para adjuntar archivos
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
              ),
              child: const Text('Adjuntar'),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavegacion('Atrás', () {}),
                _buildNavegacion('Siguiente', () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildInput(String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> opciones) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        hint: const Text('Selecciona una opción'),
        items: opciones.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {},
      ),
    );
  }

  Widget _buildNavegacion(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(140, 48),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}