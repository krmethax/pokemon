import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

class TeamController extends GetxController {
  final box = GetStorage();

  var teamMembers = <Map<String, String>>[].obs;
  var savedTeams = <Map<String, dynamic>>[].obs;
  var pokemonsList = <Map<String, String>>[].obs;

  var types = <String>[].obs;
  var selectedType = ''.obs;
  var isLoading = false.obs;
  var teamName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedTeams();
    fetchPokemons();
  }

  void loadSavedTeams() {
    final stored = box.read<List>('savedTeams');
    if (stored != null) {
      savedTeams.value = stored.map((e) {
        final team = Map<String, dynamic>.from(e);
        team['members'] = (team['members'] as List)
            .map((m) => Map<String, String>.from(m))
            .toList();
        return team;
      }).toList();
    }
  }

  Future<void> fetchPokemons() async {
    isLoading.value = true;
    try {
      final response =
          await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, String>> tempList = [];
        List<String> tempTypes = [];

        final futures = data['results'].map<Future<void>>((e) async {
          try {
            final detailResp = await http.get(Uri.parse(e['url']));
            if (detailResp.statusCode == 200) {
              final detail = json.decode(detailResp.body);
              final pokeTypes = (detail['types'] as List)
                  .map((t) => t['type']['name'] as String)
                  .toList();

              for (var t in pokeTypes) {
                if (!tempTypes.contains(t)) tempTypes.add(t);
              }

              tempList.add({
                'name': e['name'],
                'imageUrl':
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${data['results'].indexOf(e) + 1}.png',
                'types': pokeTypes.join(','),
              });
            } else {
              developer.log('Failed to fetch details for ${e['name']}',
                  error: 'Status code ${detailResp.statusCode}');
            }
          } catch (err, st) {
            developer.log('Error fetching details for ${e['name']}', error: err, stackTrace: st);
          }
        }).toList();

        await Future.wait(futures);

        pokemonsList.value = tempList;
        types.value = tempTypes;
      } else {
        developer.log('Failed to fetch Pokemon list',
            error: 'Status code ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching Pokemons', error: e, stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, String>> get filteredPokemonsByType {
    if (selectedType.value.isEmpty) return pokemonsList;
    return pokemonsList
        .where((p) => p['types']!.contains(selectedType.value))
        .toList();
  }

  // แก้ไข togglePokemon ให้เลือกได้ไม่เกิน 3 ตัว
  void togglePokemon(Map<String, String> p) {
    if (teamMembers.any((m) => m['name'] == p['name'])) {
      teamMembers.removeWhere((m) => m['name'] == p['name']);
    } else {
      if (teamMembers.length >= 3) {
        Get.snackbar(
          'จำกัดสมาชิก',
          'คุณสามารถเลือกโปเกมอนได้ไม่เกิน 3 ตัว',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      teamMembers.add(p);
    }
  }

  void saveTeam() {
    if (teamName.value.isEmpty || teamMembers.isEmpty) return;

    savedTeams.add({
      'name': teamName.value,
      'members': teamMembers.toList(),
    });
    box.write('savedTeams', savedTeams);

    teamName.value = '';
    teamMembers.clear();
  }

  void updateTeamName(int index, String newName) {
    if (index >= 0 && index < savedTeams.length) {
      savedTeams[index]['name'] = newName;
      savedTeams.refresh();
      box.write('savedTeams', savedTeams);
    }
  }

  void removeTeam(int index) {
    if (index >= 0 && index < savedTeams.length) {
      savedTeams.removeAt(index);
      box.write('savedTeams', savedTeams);
    }
  }

  String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
