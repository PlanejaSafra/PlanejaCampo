import 'package:validators/validators.dart' as validator;
import 'dart:math';
import 'package:xml/xml.dart' as xml;
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/models/talhao.dart';

class Validators {
  static bool isValidCPF(String cpf) {
    if (cpf.isEmpty) return true;  // Aceita campo em branco
    return validator.isLength(cpf, 11, 11) && _isValidCPF(cpf);
  }

  static bool isValidCNPJ(String cnpj) {
    if (cnpj.isEmpty) return true;  // Aceita campo em branco
    return validator.isLength(cnpj, 14, 14) && _isValidCNPJ(cnpj);
  }

  static bool _isValidCPF(String cpf) {
    if (cpf.length != 11) return false;

    // Remover caracteres não numéricos
    cpf = cpf.replaceAll(RegExp(r'\D'), '');

    // Verificar se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    // Calcular os dígitos verificadores
    List<int> numbers = cpf.split('').map(int.parse).toList();
    int sum = 0;

    for (int i = 0; i < 9; i++) {
      sum += numbers[i] * (10 - i);
    }

    int firstVerifier = (sum * 10 % 11) % 10;
    if (firstVerifier != numbers[9]) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += numbers[i] * (11 - i);
    }

    int secondVerifier = (sum * 10 % 11) % 10;
    return secondVerifier == numbers[10];
  }

  static bool _isValidCNPJ(String cnpj) {
    if (cnpj.length != 14) return false;

    // Remover caracteres não numéricos
    cnpj = cnpj.replaceAll(RegExp(r'\D'), '');

    // Verificar se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cnpj)) return false;

    // Calcular os dígitos verificadores
    List<int> numbers = cnpj.split('').map(int.parse).toList();
    int sum = 0;
    List<int> weight1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    List<int> weight2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    for (int i = 0; i < 12; i++) {
      sum += numbers[i] * weight1[i];
    }

    int firstVerifier = (sum % 11 < 2) ? 0 : 11 - (sum % 11);
    if (firstVerifier != numbers[12]) return false;

    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += numbers[i] * weight2[i];
    }

    int secondVerifier = (sum % 11 < 2) ? 0 : 11 - (sum % 11);
    return secondVerifier == numbers[13];
  }

  double calculatePolygonArea(List<List<double>> coordinates) {
    if (coordinates.length < 3) {
      return 0.0;
    }

    // Compute the centroid latitude to minimize distortion
    double sumLat = 0.0;
    double sumLon = 0.0;
    for (int i = 0; i < coordinates.length; i++) {
      sumLat += coordinates[i][0];
      sumLon += coordinates[i][1];
    }
    double lat0 = sumLat / coordinates.length;
    double lon0 = sumLon / coordinates.length;

    const double earthRadius = 6378137.0; // Earth's radius in meters
    double lat0Rad = lat0 * (pi / 180.0);
    double cosLat0 = cos(lat0Rad);

    List<List<double>> xyCoordinates = [];

    for (int i = 0; i < coordinates.length; i++) {
      double latRad = coordinates[i][0] * (pi / 180.0);
      double lonRad = coordinates[i][1] * (pi / 180.0);

      double x = earthRadius * (lonRad - lon0 * (pi / 180.0)) * cosLat0;
      double y = earthRadius * (latRad - lat0Rad);

      xyCoordinates.add([x, y]);
    }

    // Calculate area using shoelace formula
    double area = 0.0;
    int n = xyCoordinates.length;
    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += xyCoordinates[i][0] * xyCoordinates[j][1];
      area -= xyCoordinates[j][0] * xyCoordinates[i][1];
    }
    area = area.abs() / 2.0;

    double hectares = area / 10000.0; // Convert from square meters to hectares

    return double.parse(hectares.toStringAsFixed(2)); // Round to two decimal places
  }

  List<Talhao> parseKml(Propriedade propriedade, String kmlContent) {
    List<Talhao> talhoes = [];

    final document = xml.XmlDocument.parse(kmlContent);
    final placemarks = document.findAllElements('Placemark');

    for (var placemark in placemarks) {
      String nome = placemark.getElement('name')?.text ?? 'Unnamed';
      String? areaText = placemark
          .findElements('ExtendedData')
          .expand((e) => e.findElements('Data'))
          .firstWhere(
            (data) => data.getAttribute('name') == 'area',
        orElse: () => xml.XmlElement(xml.XmlName('Data')),
      )
          .getElement('value')
          ?.text;

      double area = double.tryParse(areaText ?? '') ?? 0.0;

      // Extrair coordenadas
      var coordinatesElement = placemark.findAllElements('coordinates').firstWhere(
            (element) => true,
        orElse: () => xml.XmlElement(xml.XmlName('coordinates')),
      );
      String coordinatesText = coordinatesElement.text.trim();
      List<Map<String, double>>? coordenadas;

      if (coordinatesText.isNotEmpty) {
        coordenadas = coordinatesText.split(RegExp(r'\s+')).map((coord) {
          var parts = coord.split(',');
          if (parts.length >= 2) {
            double longitude = double.tryParse(parts[0]) ?? 0.0;
            double latitude = double.tryParse(parts[1]) ?? 0.0;
            return {'lat': latitude, 'lon': longitude};
          }
          return {'lat': 0.0, 'lon': 0.0};
        }).toList();
      }

      // Calcular a área se a área estiver zerada
      if (area == 0.0 && coordenadas != null && coordenadas.length >= 3) {
        // Converter para List<List<double>> temporariamente para o cálculo
        List<List<double>> coordList = coordenadas.map((e) => [e['lat']!, e['lon']!]).toList();
        area = Validators().calculatePolygonArea(coordList);

        // As coordenadas já estão no formato List<Map<String, double>>
      }

      Talhao talhao = Talhao(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID temporário
        nome: nome,
        area: area,
        produtorId: propriedade.produtorId,
        propriedadeId: propriedade.id,
        coordenadas: coordenadas,
      );

      talhoes.add(talhao);
    }

    return talhoes;
  }

}
