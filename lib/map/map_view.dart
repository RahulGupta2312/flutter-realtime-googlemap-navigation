import 'package:flutter/material.dart';
import 'package:flutter_map_live_tracking/base/widget_view.dart';
import 'package:flutter_map_live_tracking/map/map_screen.dart';
import 'package:flutter_map_live_tracking/util/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends WidgetView<MapScreen, MapScreenController> {
  MapView(MapScreenController state) : super(state);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Map Marker Movement"),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(state.playing ? Icons.pause : Icons.play_arrow),
        onPressed: (){
          state.manageMarkerMovement();
        },
      ),
      body:GoogleMap(
              markers: state.polyLinePoints.isNotEmpty
                  ? Set.of(
                      {state.startMarker, state.endMarker, state.movingMarker})
                  : Set(),
              initialCameraPosition:
                  CameraPosition(target: state.initialPosition, zoom: state.zoom,
                  tilt: MapScreenController.TILT),
              onMapCreated: (mapController) {
                mapController.setMapStyle(Utils.mapStyles);
                state.completer.complete(mapController);
                state.initializeMapComponents();
              },
        onCameraMove: (position){
          state.zoom = position.zoom;
        },
              zoomControlsEnabled: false,
              polylines: state.polyline == null
                  ? Set()
                  : Set<Polyline>.of({state.polyline}),
            ),

    );
  }
}
