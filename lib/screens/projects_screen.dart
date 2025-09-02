// lib/screens/projects_screen.dart
import 'package:flutter/material.dart';
import '../db/app_db.dart';
import 'survey_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final AppDb db = AppDb();
  final TextEditingController _ctrl = TextEditingController(text: 'New Survey Project');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _createAndOpenProject() async {
    final name = _ctrl.text.trim().isEmpty ? 'Project' : _ctrl.text.trim();
    final id = await db.createProject(name);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyScreen(projectId: id, database: db),
      ),
    );
    if (!mounted) return;
    setState(() {}); // refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GeoMag — Projects')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(labelText: 'Project name'),
                    onSubmitted: (_) => _createAndOpenProject(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                  onPressed: _createAndOpenProject,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Project>>(
              future: db.listProjects(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final items = snap.data ?? <Project>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No projects yet. Create one to begin.'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = items[i];
                    return ListTile(
                      title: Text(p.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurveyScreen(projectId: p.id, database: db),
                          ),
                        );
                        if (!mounted) return;
                        setState(() {});
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
