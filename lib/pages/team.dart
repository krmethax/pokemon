import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import 'team_detail.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeamController());
    final teamNameController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Team Builder'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // แสดงทีมที่บันทึกไว้
            Obx(() {
              if (controller.savedTeams.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ทีมของฉัน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.savedTeams.length,
                      itemBuilder: (_, index) {
                        final team = controller.savedTeams[index];
                        return GestureDetector(
                          onTap: () => Get.to(() => TeamDetailPage(teamIndex: index)),
                          child: Container(
                            width: 180,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(8),
                            color: Colors.white,
                            child: Column(
                              children: [
                                Text(
                                  team['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: team['members'].length,
                                    itemBuilder: (_, i) {
                                      final p = team['members'][i];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: Column(
                                          children: [
                                            Image.network(p['imageUrl']!, width: 40, height: 40),
                                            Text(
                                              controller.capitalize(p['name']!),
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 12),
            // ตัวกรอง Type
            Obx(() {
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: controller.types
                      .map(
                        (type) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Obx(() => ChoiceChip(
                                label: Text(
                                  controller.capitalize(type),
                                  style: TextStyle(
                                    color: controller.selectedType.value == type
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                selected: controller.selectedType.value == type,
                                selectedColor: Colors.red,
                                onSelected: (val) {
                                  controller.selectedType.value = val ? type : '';
                                },
                                backgroundColor: Colors.white,
                              )),
                        ),
                      )
                      .toList(),
                ),
              );
            }),

            const SizedBox(height: 12),
            // รายการ Pokémon
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.red));
                }
                final pokemons = controller.filteredPokemonsByType;
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
                      final isSelected = controller.teamMembers
                          .any((m) => m['name'] == p['name']);
                      final canSelect = isSelected || controller.teamMembers.length < 3;
                      return GestureDetector(
                        onTap: canSelect ? () => controller.togglePokemon(p) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                              AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Opacity(
                                    opacity: canSelect ? 1.0 : 0.4,
                                    child: Image.network(p['imageUrl']!,
                                        fit: BoxFit.contain),
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

            // กรอกชื่อทีม + ปุ่มบันทึก
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: teamNameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อทีม',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => controller.teamName.value = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => ElevatedButton(
                        onPressed: controller.teamName.value.isNotEmpty &&
                                controller.teamMembers.isNotEmpty
                            ? () {
                                controller.saveTeam();
                                teamNameController.clear();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'บันทึกทีม',
                          style: TextStyle(color: Colors.white),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
