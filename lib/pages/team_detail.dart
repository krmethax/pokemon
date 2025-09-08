import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import 'edit_team.dart';

class TeamDetailPage extends StatelessWidget {
  final int teamIndex;

  const TeamDetailPage({super.key, required this.teamIndex});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamController>();
    // ดึงข้อมูลทีมจาก savedTeams
    final team = controller.savedTeams[teamIndex];

    // สร้าง observable list สำหรับสมาชิกทีมนี้ (เพื่อแก้ไขเฉพาะหน้านี้)
    final teamMembers = RxList<Map<String, String>>.from(team['members']);

    return Scaffold(
      appBar: AppBar(
        title: Text(team['name']),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.to(() => EditTeamPage(teamIndex: teamIndex));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              controller.removeTeam(teamIndex);
              Get.back();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // รายการ Pokémon ของทีม
            Expanded(
              child: Obx(() {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: controller.pokemonsList.length,
                  itemBuilder: (_, index) {
                    final p = controller.pokemonsList[index];
                    final isSelected = teamMembers.any((m) => m['name'] == p['name']);
                    final canSelect = isSelected || teamMembers.length < 3;

                    return GestureDetector(
                      onTap: canSelect
                          ? () {
                              if (isSelected) {
                                teamMembers.removeWhere((m) => m['name'] == p['name']);
                              } else {
                                teamMembers.add(p);
                              }
                              // อัพเดตทีมจริงใน controller
                              controller.savedTeams[teamIndex]['members'] = teamMembers.toList();
                              controller.savedTeams.refresh();
                              controller.box.write('savedTeams', controller.savedTeams);
                            }
                          : null,
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
                                  child: Image.network(
                                    p['imageUrl']!,
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
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
