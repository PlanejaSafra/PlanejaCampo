import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:geodesy/geodesy.dart' as geodesy; // Biblioteca para cálculos geográficos
import 'package:planejacampo/utils/validators.dart';

class MapDrawingScreen extends StatefulWidget {
  final String talhaoNome;
  final List<Map<String, double>>? initialCoordinates;

  const MapDrawingScreen({
    Key? key,
    required this.talhaoNome,
    this.initialCoordinates,
  }) : super(key: key);

  @override
  _MapDrawingScreenState createState() => _MapDrawingScreenState();
}

class _MapDrawingScreenState extends State<MapDrawingScreen> {
  Completer<gmaps.GoogleMapController> _controller = Completer();
  List<gmaps.LatLng> _polygonLatLngs = [];
  Set<gmaps.Marker> _markers = {};
  gmaps.Polygon? _polygon;
  String _nomeTalhao = '';
  double _area = 0.0;

  // Variável para armazenar o ID do marcador selecionado
  gmaps.MarkerId? _selectedMarkerId;

  // Armazenar o Future da posição
  late Future<Position> _positionFuture;

  // Instância da biblioteca Geodesy para cálculos geográficos
  final geodesy.Geodesy geodesyInstance = geodesy.Geodesy();

  @override
  void initState() {
    super.initState();
    _nomeTalhao = widget.talhaoNome;
    _positionFuture = _determinePosition();

    if (widget.initialCoordinates != null && widget.initialCoordinates!.isNotEmpty) {
      _polygonLatLngs = widget.initialCoordinates!
          .map((coord) => gmaps.LatLng(coord['lat']!, coord['lon']!))
          .toList();
      _updatePolygon();
      _calculateArea();

      // Adicionando Marcadores Iniciais
      for (int i = 0; i < _polygonLatLngs.length; i++) {
        _addMarker(_polygonLatLngs[i], i);
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está ativado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Solicita ao usuário para ativar o serviço de localização
      return Future.error('Serviços de localização estão desativados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissão negada
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissão negada permanentemente
      return Future.error(
          'Permissão de localização negada permanentemente, não podemos solicitar permissões.');
    }

    // Quando permissões são concedidas, retorna a posição atual
    return await Geolocator.getCurrentPosition();
  }

  // Função para calcular a área do polígono (em metros quadrados) usando Geodesy
  void _calculateArea() {
    if (_polygonLatLngs.length < 3) {
      setState(() {
        _area = 0.0;
      });
      return;
    }

    // Converter gmaps.LatLng para uma lista de List<double> para ser utilizada no Validators
    List<List<double>> coordinates = _polygonLatLngs
        .map((gmaps.LatLng latLng) => [latLng.latitude, latLng.longitude])
        .toList();

    // Utiliza a função de Validators para calcular a área
    double calculatedArea = Validators().calculatePolygonArea(coordinates);
    setState(() {
      _area = calculatedArea; // Área em hectares
    });
  }

  // Função para atualizar o polígono no mapa
  void _updatePolygon() {
    setState(() {
      _polygon = gmaps.Polygon(
        polygonId: gmaps.PolygonId('talhao'),
        points: _polygonLatLngs,
        strokeColor: Colors.blue,
        strokeWidth: 2,
        fillColor: Colors.blue.withOpacity(0.15),
      );
    });
  }

  // Função para adicionar um marcador
  void _addMarker(gmaps.LatLng position, int index) {
    _markers.add(
      gmaps.Marker(
        markerId: gmaps.MarkerId('marker_$index'),
        position: position,
        infoWindow: gmaps.InfoWindow(title: 'Ponto ${index + 1}'),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
        onTap: () {
          _onMarkerTapped(gmaps.MarkerId('marker_$index'));
        },
      ),
    );
  }

  void _onMapTapped(gmaps.LatLng position) {
    setState(() {
      // Adicionar a nova coordenada
      _polygonLatLngs.add(position);
      _updatePolygon();
      _calculateArea();

      // Adicionar um marcador para representar o ponto
      int index = _polygonLatLngs.length - 1;
      _addMarker(position, index);

      // Atualizar o marcador anteriormente selecionado, se houver
      if (_selectedMarkerId != null) {
        final selectedMarker = _markers.firstWhere(
              (marker) => marker.markerId == _selectedMarkerId,
          orElse: () => gmaps.Marker(markerId: gmaps.MarkerId('invalid')),
        );
        if (selectedMarker.markerId.value != 'invalid') {
          _markers.remove(selectedMarker);
          _markers.add(
            selectedMarker.copyWith(
              iconParam: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
            ),
          );
        }
        _selectedMarkerId = null;
      }
    });
  }

  void _onMarkerTapped(gmaps.MarkerId markerId) {
    setState(() {
      // Atualizar o marcador anteriormente selecionado, se houver
      if (_selectedMarkerId != null && _selectedMarkerId != markerId) {
        final previousMarker = _markers.firstWhere(
              (marker) => marker.markerId == _selectedMarkerId,
          orElse: () => gmaps.Marker(markerId: gmaps.MarkerId('invalid')),
        );
        if (previousMarker.markerId.value != 'invalid') {
          _markers.remove(previousMarker);
          _markers.add(
            previousMarker.copyWith(
              iconParam: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
            ),
          );
        }
      }

      // Selecionar o novo marcador
      final tappedMarker = _markers.firstWhere(
            (marker) => marker.markerId == markerId,
        orElse: () => gmaps.Marker(markerId: gmaps.MarkerId('invalid')),
      );
      if (tappedMarker.markerId.value != 'invalid') {
        _markers.remove(tappedMarker);
        _markers.add(
          tappedMarker.copyWith(
            iconParam: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
            draggableParam: true,
            onDragEndParam: (newPosition) {
              _onMarkerDragged(markerId, newPosition);
            },
          ),
        );
        _selectedMarkerId = markerId;

        // Exibir o diálogo para excluir o marcador
        _showDeleteMarkerDialog(markerId);
      }
    });
  }

  // Função para exibir o diálogo de exclusão do marcador
  void _showDeleteMarkerDialog(gmaps.MarkerId markerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Ponto'),
          content: Text('Deseja excluir este ponto?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                // Deselecionar o marcador sem excluir
                setState(() {
                  final currentMarker = _markers.firstWhere(
                        (marker) => marker.markerId == markerId,
                    orElse: () => gmaps.Marker(markerId: gmaps.MarkerId('invalid')),
                  );
                  if (currentMarker.markerId.value != 'invalid') {
                    _markers.remove(currentMarker);
                    _markers.add(
                      currentMarker.copyWith(
                        iconParam: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
                      ),
                    );
                  }
                  _selectedMarkerId = null;
                });
              },
            ),
            TextButton(
              child: Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMarker(markerId);
              },
            ),
          ],
        );
      },
    );
  }

  // Função para deletar o marcador selecionado
  void _deleteMarker(gmaps.MarkerId markerId) {
    setState(() {
      // Extrair o índice a partir do markerId
      final String markerIdValue = markerId.value; // ex: 'marker_0'
      final int index = int.parse(markerIdValue.split('_')[1]);

      // Remover a coordenada correspondente
      _polygonLatLngs.removeAt(index);

      // Remover o marcador
      _markers.removeWhere((marker) => marker.markerId == markerId);

      // Reindexar e reconstruir os marcadores restantes
      _markers.clear();
      for (int i = 0; i < _polygonLatLngs.length; i++) {
        final markerIndex = i;
        _addMarker(_polygonLatLngs[i], markerIndex);
      }

      // Atualizar o polígono
      if (_polygonLatLngs.length >= 3) {
        _updatePolygon();
      } else {
        _polygon = null;
      }

      // Recalcular a área
      _calculateArea();

      // Resetar o marcador selecionado
      _selectedMarkerId = null;
    });
  }

  void _onMarkerDragged(gmaps.MarkerId markerId, gmaps.LatLng newPosition) {
    setState(() {
      // Remover o marcador antigo
      _markers.removeWhere((marker) => marker.markerId == markerId);

      // Atualizar a posição na lista de coordenadas
      int index = int.parse(markerId.value.split('_')[1]);
      _polygonLatLngs[index] = newPosition;

      // Adicionar o marcador atualizado
      _markers.add(
        gmaps.Marker(
          markerId: markerId,
          position: newPosition,
          infoWindow: gmaps.InfoWindow(title: 'Ponto Atualizado'),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
          draggable: true,
          onDragEnd: (updatedPosition) {
            _onMarkerDragged(markerId, updatedPosition);
          },
          onTap: () {
            _onMarkerTapped(markerId);
          },
        ),
      );

      // Atualizar o polígono
      _updatePolygon();

      // Recalcular a área
      _calculateArea();
    });
  }

  void _clearPolygon() {
    setState(() {
      _polygonLatLngs.clear();
      _polygon = null;
      _markers.clear();
      _selectedMarkerId = null;
      _area = 0.0;
    });
  }

  Future<void> _savePolygon() async {
    if (_polygonLatLngs.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, desenhe um polígono válido com pelo menos 3 pontos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final TextEditingController nomeController = TextEditingController(text: _nomeTalhao);

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Salvar Talhão'),
          content: TextField(
            controller: nomeController,
            decoration: InputDecoration(
              labelText: 'Nome do Talhão',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('Salvar'),
              onPressed: () {
                if (nomeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Por favor, insira o nome do talhão.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _nomeTalhao = nomeController.text.trim();
      });
      Navigator.of(context).pop({
        'nome': _nomeTalhao,
        'coordenadas': _polygonLatLngs
            .map((gmaps.LatLng latLng) => {'lat': latLng.latitude, 'lon': latLng.longitude})
            .toList(),
        'area': _area, // Área em metros quadrados
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Definir Talhão no Mapa'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePolygon,
            tooltip: 'Salvar Talhão',
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearPolygon,
            tooltip: 'Limpar Polígono',
          ),
        ],
      ),
      body: FutureBuilder<Position>(
        future: _positionFuture, // Usar o Future armazenado
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar localização: ${snapshot.error}'));
          } else {
            final position = snapshot.data!;
            final gmaps.CameraPosition initialCameraPosition = gmaps.CameraPosition(
              target: gmaps.LatLng(position.latitude, position.longitude),
              zoom: 16,
            );

            return gmaps.GoogleMap(
              mapType: gmaps.MapType.satellite,
              initialCameraPosition: initialCameraPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              polygons: _polygon != null ? {_polygon!} : {},
              markers: _markers,
              onTap: _onMapTapped,
              onMapCreated: (gmaps.GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
            );
          }
        },
      ),
    );
  }
}
