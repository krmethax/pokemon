import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/team_controller.dart';

class EditTeamPage extends StatelessWidget {
  final int teamIndex;

  const EditTeamPage({super.key, required this.teamIndex});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamController>();
    final team = controller.savedTeams[teamIndex];

    final nameController = TextEditingController(text: team['name']);
    final members = RxList<Map<String, String>>.from(team['members']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขทีม'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Obx(() {
              // ปุ่ม Save enabled เมื่อมีชื่อทีมและสมาชิก >=1
              final canSave = nameController.text.trim().isNotEmpty && members.isNotEmpty;
              return TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อทีม',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  // trigger rebuild ปุ่ม save
                  members.refresh();
                },
              );
            }),
          ),
          Expanded(
            child: Obx(() {
              final pokemons = controller.pokemonsList;
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: pokemons.length,
                itemBuilder: (_, index) {
                  final p = pokemons[index];
                  return Obx(() {
                    final isSelected = members.any((m) => m['name'] == p['name']);
                    final canSelect = isSelected || members.length < 3;

                    return GestureDetector(
                      onTap: canSelect
                          ? () {
                              if (isSelected) {
                                members.removeWhere((m) => m['name'] == p['name']);
                              } else {
                                members.add(p);
                              }
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Colors.red
                                : canSelect
                                    ? Colors.grey
                                    : Colors.grey.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Opacity(
                                  opacity: canSelect ? 1.0 : 0.4,
                                  child: CachedNetworkImage(
                                    imageUrl: p['imageUrl']!,
                                    placeholder: (context, url) =>
                                        const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.capitalize(p['name']!),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Obx(() {
              final canSave = nameController.text.trim().isNotEmpty && members.isNotEmpty;
              return ElevatedButton(
                onPressed: canSave
                    ? () {
                        controller.updateTeamName(teamIndex, nameController.text.trim());
                        controller.savedTeams[teamIndex]['members'] = members.toList();
                        controller.savedTeams.refresh();
                        controller.box.write('savedTeams', controller.savedTeams);
                        Get.back();
                      }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'บันทึกการแก้ไข',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
