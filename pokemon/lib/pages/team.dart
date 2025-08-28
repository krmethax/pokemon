import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final box = GetStorage();

  List<Map<String, String>> teamMembers = [];
  List<Map<String, dynamic>> savedTeams = [];
  List<Map<String, String>> pokemonsList = [];

  List<String> types = [];
  String selectedType = '';
  bool isLoading = false;
  String teamName = '';

  late TextEditingController teamNameController;

  @override
  void initState() {
    super.initState();
    teamNameController = TextEditingController();
    loadSavedTeams();
    fetchPokemons();
  }

  @override
  void dispose() {
    teamNameController.dispose();
    super.dispose();
  }

  void loadSavedTeams() {
    final stored = box.read<List>('savedTeams');
    if (stored != null) {
      setState(() {
        savedTeams = stored.map((e) {
          final team = Map<String, dynamic>.from(e);
          team['members'] = (team['members'] as List)
              .map((m) => Map<String, String>.from(m))
              .toList();
          return team;
        }).toList();
      });
    }
  }

  Future<void> fetchPokemons() async {
    setState(() => isLoading = true);
    try {
      final response =
          await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, String>> tempList = [];
        List<String> tempTypes = [];

        for (var e in data['results']) {
          final url = e['url'];
          final detailResp = await http.get(Uri.parse(url));
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
          }
        }

        setState(() {
          pokemonsList = tempList;
          types = tempTypes;
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, String>> get filteredPokemonsByType {
    if (selectedType.isEmpty) return pokemonsList;
    return pokemonsList
        .where((p) => p['types']!.contains(selectedType))
        .toList();
  }

  void togglePokemon(Map<String, String> p) {
    setState(() {
      if (teamMembers.any((m) => m['name'] == p['name'])) {
        teamMembers.removeWhere((m) => m['name'] == p['name']);
      } else {
        teamMembers.add(p);
      }
    });
  }

  void saveTeam() {
    if (teamName.isEmpty || teamMembers.isEmpty) return;

    setState(() {
      savedTeams.add({
        'name': teamName,
        'members': teamMembers.map((e) => e).toList(),
      });
      box.write('savedTeams', savedTeams);
      teamName = '';
      teamMembers.clear();
      teamNameController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ทีมของคุณถูกบันทึกแล้ว')),
    );
  }

  void editTeam(int index) {
    final team = savedTeams[index];
    setState(() {
      teamName = team['name'];
      teamMembers = List<Map<String, String>>.from(team['members']);
      teamNameController.text = teamName;
    });
  }

  void removeTeam(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบทีม'),
        content: const Text('คุณต้องการลบทีมหรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          TextButton(
              onPressed: () {
                setState(() {
                  savedTeams.removeAt(index);
                  box.write('savedTeams', savedTeams);
                });
                Navigator.pop(context);
              },
              child: const Text('ลบ', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokémon Team Builder')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ทีมของฉัน
            if (savedTeams.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ทีมของฉัน',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: savedTeams.length,
                      itemBuilder: (context, index) {
                        final team = savedTeams[index];
                        final members = List<Map<String, String>>.from(team['members']);
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(8),
                          color: Colors.white,
                          child: Column(
                            children: [
                              Text(team['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: members.length,
                                  itemBuilder: (_, i) {
                                    final p = members[i];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Column(
                                        children: [
                                          Image.network(
                                            p['imageUrl']!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                          Text(capitalize(p['name']!),
                                              style: const TextStyle(fontSize: 10, color: Colors.black))
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Colors.black),
                                    onPressed: () => editTeam(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.black),
                                    onPressed: () => removeTeam(index),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),
            // กรองตามประเภท
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: types
                    .map((type) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(capitalize(type), style: const TextStyle(color: Colors.black)),
                            selected: selectedType == type,
                            selectedColor: Colors.black,
                            onSelected: (val) {
                              setState(() {
                                selectedType = val ? type : '';
                              });
                            },
                            backgroundColor: Colors.white,
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),
            // รายชื่อ Pokémon
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredPokemonsByType.length,
                      itemBuilder: (context, index) {
                        final p = filteredPokemonsByType[index];
                        final isSelected =
                            teamMembers.any((m) => m['name'] == p['name']);
                        return GestureDetector(
                          onTap: () => togglePokemon(p),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Image.network(p['imageUrl']!, fit: BoxFit.contain),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  capitalize(p['name']!),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ชื่อทีม + ปุ่มบันทึก
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'ชื่อทีม', border: OutlineInputBorder()),
                      controller: teamNameController,
                      onChanged: (v) => teamName = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: saveTeam,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text('บันทึกทีม', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
